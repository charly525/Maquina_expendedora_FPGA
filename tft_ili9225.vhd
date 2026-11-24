-- =====================================================================
-- tft_ili9225.vhd   (version con imagenes)
-- Controlador de la pantalla TFT 2.2" 176x220 (ILI9225) por SPI.
--
-- 1. Reset fisico e inicializacion (lista de registros INIT_ROM).
-- 2. Bucle infinito: define la ventana de toda la pantalla y envia los
--    38.720 pixeles, de arriba a abajo y de izquierda a derecha.
--    El color de cada pixel sale de:
--      - la ROM de pantallas (pantallas.mif): 9 imagenes de 88x110 con
--        4 bits por pixel; cada pixel de la imagen cubre 2x2 de la pantalla.
--      - la ROM de digitos (digitos.mif), para los numeros que cambian
--        (creditos, saldo, total), dibujados encima de la imagen.
--      - la PALETA de 16 colores (pantallas_pkg.vhd) -> color RGB565.
--    Los datos de la escena se "congelan" al empezar cada cuadro, para
--    que una imagen nunca quede mitad de una y mitad de otra.
-- Un cuadro completo tarda ~110 ms (unas 9 imagenes por segundo).
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.pantallas_pkg.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity tft_ili9225 is
    generic (
        DIV_SPI   : natural := 4;        -- SCK = 50 MHz / (2*4) = 6.25 MHz
        CICLOS_MS : natural := 50_000    -- ciclos de reloj en 1 ms
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        -- que dibujar (desde escenas.vhd)
        escena   : in  natural range 0 to P_N - 1;
        rebote   : in  natural range 0 to 3;
        ov_en    : in  std_logic;
        ov_x     : in  natural range 0 to P_ANCHO - 1;
        ov_y     : in  natural range 0 to P_ALTO - 1;
        ov_n     : in  natural range 1 to 3;
        ov_d0    : in  natural range 0 to 9;
        ov_d1    : in  natural range 0 to 9;
        ov_d2    : in  natural range 0 to 9;
        -- pines de la pantalla
        tft_cs   : out std_logic;
        tft_rs   : out std_logic;
        tft_rst  : out std_logic;
        tft_sck  : out std_logic;
        tft_sdi  : out std_logic;
        listo    : out std_logic        -- '1' cuando ya termino de inicializar
    );
end entity;

architecture rtl of tft_ili9225 is

    -- ------------------- ROM de inicializacion -----------------------
    -- (registro, valor). Registro x"FF" = pausa de 'valor' milisegundos.
    type t_ini is record
        reg : std_logic_vector(7 downto 0);
        val : std_logic_vector(15 downto 0);
    end record;
    type t_ini_rom is array (natural range <>) of t_ini;
    constant INIT_ROM : t_ini_rom := (
        (x"10", x"0000"), (x"11", x"0000"), (x"12", x"0000"),   -- energia apagada
        (x"13", x"0000"), (x"14", x"0000"), (x"FF", x"0028"),   -- 40 ms
        (x"11", x"0018"), (x"12", x"6121"), (x"13", x"006F"),   -- secuencia de encendido
        (x"14", x"495F"), (x"10", x"0800"), (x"FF", x"000A"),   -- 10 ms
        (x"11", x"103B"), (x"FF", x"0032"),                     -- 50 ms
        (x"01", x"011C"),   -- control de salida: 220 lineas
        (x"02", x"0100"),   -- control de barrido LCD
        (x"03", x"1030"),   -- modo de entrada: x++ luego y++
        (x"07", x"0000"),   -- display apagado mientras se configura
        (x"08", x"0808"), (x"0B", x"1100"), (x"0C", x"0000"),
        (x"0F", x"0D01"), (x"15", x"0020"),
        (x"20", x"0000"), (x"21", x"0000"),
        (x"30", x"0000"), (x"31", x"00DB"), (x"32", x"0000"),
        (x"33", x"0000"), (x"34", x"00DB"), (x"35", x"0000"),
        (x"36", x"00AF"), (x"37", x"0000"),                     -- ventana x 0..175
        (x"38", x"00DB"), (x"39", x"0000"),                     -- ventana y 0..219
        (x"50", x"0000"), (x"51", x"0808"), (x"52", x"080A"),   -- curva gamma
        (x"53", x"000A"), (x"54", x"0A08"), (x"55", x"0808"),
        (x"56", x"0000"), (x"57", x"0A00"), (x"58", x"0710"),
        (x"59", x"0710"),
        (x"07", x"0012"), (x"FF", x"0032"),                     -- 50 ms
        (x"07", x"1017"), (x"FF", x"000A")                      -- display encendido
    );
    constant INIT_LEN : natural := INIT_ROM'length;

    constant N_PIX_TOTAL : natural := 176 * 220;

    -- direccion donde empieza cada imagen dentro de la ROM
    type t_bases is array (0 to P_N - 1) of natural range 0 to ROM_PROF;
    function calc_bases return t_bases is
        variable b : t_bases;
    begin
        for i in 0 to P_N - 1 loop
            b(i) := i * P_TAM;
        end loop;
        return b;
    end function;
    constant BASES : t_bases := calc_bases;

    -- ------------------- emisor SPI ----------------------------------
    type t_spi is (S_IDLE, S_BAJO, S_ALTO, S_FIN);
    signal spi_est   : t_spi := S_IDLE;
    signal spi_cnt   : natural range 0 to 255 := 0;
    signal spi_bit   : natural range 0 to 15 := 0;
    signal spi_sh    : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_start  : std_logic := '0';
    signal tx_rs     : std_logic := '0';
    signal tx_dato   : std_logic_vector(15 downto 0) := (others => '0');
    signal tx_fin    : std_logic := '0';

    -- ------------------- secuenciador --------------------------------
    type t_seq is (
        Q_RST_BAJO, Q_RST_ESPERA,
        Q_INIT, Q_PAUSA,
        Q_VENTANA, Q_PIXELES
    );
    signal seq       : t_seq := Q_RST_BAJO;
    signal esperando : std_logic := '0';
    signal cnt_ms    : unsigned(15 downto 0) := (others => '0');
    signal cnt_ciclo : unsigned(15 downto 0) := (others => '0');
    signal ms_obj    : unsigned(15 downto 0) := (others => '0');
    signal ini_idx   : natural range 0 to 63 := 0;
    signal medio     : std_logic := '0';
    signal win_paso  : natural range 0 to 12 := 0;
    signal listo_i   : std_logic := '0';

    -- ------------------- barrido de pixeles --------------------------
    signal px        : natural range 0 to 175 := 0;   -- columna en pantalla
    signal py        : natural range 0 to 219 := 0;   -- fila en pantalla
    signal fase      : natural range 0 to 3 := 0;     -- 0 dir, 1-2 espera ROM, 3 enviar

    -- escena congelada al inicio de cada cuadro
    signal e_esc     : natural range 0 to P_N - 1 := 0;
    signal e_reb     : natural range 0 to 3 := 0;
    signal e_ov_en   : std_logic := '0';
    signal e_ov_x    : natural range 0 to P_ANCHO - 1 := 0;
    signal e_ov_y    : natural range 0 to P_ALTO - 1 := 0;
    signal e_ov_n    : natural range 1 to 3 := 2;
    type t_dig3 is array (0 to 2) of natural range 0 to 9;
    signal e_dig     : t_dig3 := (others => 0);

    -- memorias
    signal rom_dir   : std_logic_vector(16 downto 0) := (others => '0');
    signal rom_q     : std_logic_vector(3 downto 0);
    signal dig_dir   : std_logic_vector(10 downto 0) := (others => '0');
    signal dig_q     : std_logic_vector(3 downto 0);
    signal es_fondo  : std_logic := '0';    -- fuera de la imagen por el rebote
    signal en_digito : std_logic := '0';
    signal color     : std_logic_vector(15 downto 0) := (others => '0');

begin

    -- =================================================================
    -- Memorias ROM (bloques M9K de la FPGA, contenido en archivos .mif)
    -- =================================================================
    u_rom_pantallas: altsyncram
        generic map (
            operation_mode         => "ROM",
            width_a                => 4,
            widthad_a              => 17,
            numwords_a             => ROM_PROF,
            init_file              => "pantallas.mif",
            outdata_reg_a          => "UNREGISTERED",
            address_aclr_a         => "NONE",
            outdata_aclr_a         => "NONE",
            clock_enable_input_a   => "BYPASS",
            clock_enable_output_a  => "BYPASS",
            intended_device_family => "Cyclone III",
            lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
            lpm_type               => "altsyncram"
        )
        port map (
            clock0    => clk,
            address_a => rom_dir,
            q_a       => rom_q
        );

    u_rom_digitos: altsyncram
        generic map (
            operation_mode         => "ROM",
            width_a                => 4,
            widthad_a              => 11,
            numwords_a             => 10 * DIG_ANCHO * DIG_ALTO,
            init_file              => "digitos.mif",
            outdata_reg_a          => "UNREGISTERED",
            address_aclr_a         => "NONE",
            outdata_aclr_a         => "NONE",
            clock_enable_input_a   => "BYPASS",
            clock_enable_output_a  => "BYPASS",
            intended_device_family => "Cyclone III",
            lpm_hint               => "ENABLE_RUNTIME_MOD=NO",
            lpm_type               => "altsyncram"
        )
        port map (
            clock0    => clk,
            address_a => dig_dir,
            q_a       => dig_q
        );

    -- =================================================================
    -- Emisor SPI: envia tx_dato (16 bits) con RS = tx_rs.
    -- tx_start: pulso de inicio. tx_fin: pulso al terminar.
    -- =================================================================
    process(clk)
    begin
        if rising_edge(clk) then
            tx_fin <= '0';
            if rst = '1' then
                spi_est <= S_IDLE;
                tft_cs  <= '1';
                tft_sck <= '0';
            else
                case spi_est is
                    when S_IDLE =>
                        tft_cs  <= '1';
                        tft_sck <= '0';
                        if tx_start = '1' then
                            tft_cs  <= '0';
                            tft_rs  <= tx_rs;
                            spi_sh  <= tx_dato;
                            tft_sdi <= tx_dato(15);
                            spi_bit <= 15;
                            spi_cnt <= 0;
                            spi_est <= S_BAJO;
                        end if;

                    when S_BAJO =>                     -- SCK en bajo
                        if spi_cnt = DIV_SPI - 1 then
                            spi_cnt <= 0;
                            tft_sck <= '1';            -- flanco de subida: la pantalla lee
                            spi_est <= S_ALTO;
                        else
                            spi_cnt <= spi_cnt + 1;
                        end if;

                    when S_ALTO =>                     -- SCK en alto
                        if spi_cnt = DIV_SPI - 1 then
                            spi_cnt <= 0;
                            tft_sck <= '0';
                            if spi_bit = 0 then
                                spi_est <= S_FIN;
                            else
                                spi_bit <= spi_bit - 1;
                                spi_sh  <= spi_sh(14 downto 0) & '0';
                                tft_sdi <= spi_sh(14);
                                spi_est <= S_BAJO;
                            end if;
                        else
                            spi_cnt <= spi_cnt + 1;
                        end if;

                    when S_FIN =>
                        if spi_cnt = DIV_SPI - 1 then
                            spi_cnt <= 0;
                            tft_cs  <= '1';
                            tx_fin  <= '1';
                            spi_est <= S_IDLE;
                        else
                            spi_cnt <= spi_cnt + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- =================================================================
    -- Secuenciador principal
    -- =================================================================
    process(clk)
        procedure enviar(rs : std_logic; dato : std_logic_vector(15 downto 0)) is
        begin
            tx_rs     <= rs;
            tx_dato   <= dato;
            tx_start  <= '1';
            esperando <= '1';
        end procedure;
        variable reg_w : std_logic_vector(7 downto 0);
        variable val_w : std_logic_vector(15 downto 0);
        -- variables del calculo de direccion
        variable hx, hy  : natural range 0 to 127;
        variable ry      : integer range -4 to 127;
        variable fondo   : std_logic;
        variable rel, col: integer range -128 to 255;
        variable fila_d  : integer range -128 to 255;
        variable idx_d   : natural range 0 to 2;
        variable dig     : natural range 0 to 9;
        variable hit     : std_logic;
        variable indice  : natural range 0 to 15;
    begin
        if rising_edge(clk) then
            tx_start <= '0';

            if rst = '1' then
                seq       <= Q_RST_BAJO;
                esperando <= '0';
                cnt_ms    <= (others => '0');
                cnt_ciclo <= (others => '0');
                ini_idx   <= 0;
                medio     <= '0';
                listo_i   <= '0';
                tft_rst   <= '0';
            else
                case seq is
                    -- ---------- reset fisico ----------
                    when Q_RST_BAJO =>
                        tft_rst <= '0';
                        if cnt_ciclo = CICLOS_MS - 1 then
                            cnt_ciclo <= (others => '0');
                            if cnt_ms = 19 then          -- 20 ms en bajo
                                cnt_ms <= (others => '0');
                                seq    <= Q_RST_ESPERA;
                            else
                                cnt_ms <= cnt_ms + 1;
                            end if;
                        else
                            cnt_ciclo <= cnt_ciclo + 1;
                        end if;

                    when Q_RST_ESPERA =>
                        tft_rst <= '1';
                        if cnt_ciclo = CICLOS_MS - 1 then
                            cnt_ciclo <= (others => '0');
                            if cnt_ms = 119 then         -- 120 ms
                                cnt_ms  <= (others => '0');
                                ini_idx <= 0;
                                medio   <= '0';
                                seq     <= Q_INIT;
                            else
                                cnt_ms <= cnt_ms + 1;
                            end if;
                        else
                            cnt_ciclo <= cnt_ciclo + 1;
                        end if;

                    -- ---------- inicializacion ----------
                    when Q_INIT =>
                        if esperando = '1' then
                            if tx_fin = '1' then
                                esperando <= '0';
                                if medio = '0' then
                                    medio <= '1';
                                else
                                    medio <= '0';
                                    ini_idx <= ini_idx + 1;
                                end if;
                            end if;
                        else
                            reg_w := INIT_ROM(ini_idx).reg;
                            val_w := INIT_ROM(ini_idx).val;
                            if reg_w = x"FF" then
                                ms_obj    <= unsigned(val_w);
                                cnt_ms    <= (others => '0');
                                cnt_ciclo <= (others => '0');
                                seq       <= Q_PAUSA;
                            elsif medio = '0' then
                                enviar('0', x"00" & reg_w);
                            else
                                enviar('1', val_w);
                            end if;
                        end if;

                    when Q_PAUSA =>
                        if cnt_ciclo = CICLOS_MS - 1 then
                            cnt_ciclo <= (others => '0');
                            if cnt_ms = ms_obj - 1 or ms_obj = 0 then
                                cnt_ms <= (others => '0');
                                if ini_idx = INIT_LEN - 1 then
                                    listo_i  <= '1';      -- inicializacion terminada
                                    win_paso <= 0;
                                    seq      <= Q_VENTANA;
                                else
                                    ini_idx <= ini_idx + 1;
                                    medio   <= '0';
                                    seq     <= Q_INIT;
                                end if;
                            else
                                cnt_ms <= cnt_ms + 1;
                            end if;
                        else
                            cnt_ciclo <= cnt_ciclo + 1;
                        end if;

                    -- ---------- ventana = toda la pantalla + comando de escritura ----------
                    when Q_VENTANA =>
                        if esperando = '1' then
                            if tx_fin = '1' then
                                esperando <= '0';
                                if win_paso = 12 then
                                    win_paso <= 0;
                                    px   <= 0;
                                    py   <= 0;
                                    fase <= 0;
                                    -- congelar la escena para todo el cuadro
                                    e_esc   <= escena;
                                    e_reb   <= rebote;
                                    e_ov_en <= ov_en;
                                    e_ov_x  <= ov_x;
                                    e_ov_y  <= ov_y;
                                    e_ov_n  <= ov_n;
                                    e_dig(0) <= ov_d0;
                                    e_dig(1) <= ov_d1;
                                    e_dig(2) <= ov_d2;
                                    seq  <= Q_PIXELES;
                                else
                                    win_paso <= win_paso + 1;
                                end if;
                            end if;
                        else
                            case win_paso is
                                when 0  => enviar('0', x"0036");   -- fin horizontal
                                when 1  => enviar('1', x"00AF");   -- 175
                                when 2  => enviar('0', x"0037");   -- inicio horizontal
                                when 3  => enviar('1', x"0000");
                                when 4  => enviar('0', x"0038");   -- fin vertical
                                when 5  => enviar('1', x"00DB");   -- 219
                                when 6  => enviar('0', x"0039");   -- inicio vertical
                                when 7  => enviar('1', x"0000");
                                when 8  => enviar('0', x"0020");   -- direccion x
                                when 9  => enviar('1', x"0000");
                                when 10 => enviar('0', x"0021");   -- direccion y
                                when 11 => enviar('1', x"0000");
                                when others => enviar('0', x"0022");  -- escribir GRAM
                            end case;
                        end if;

                    -- ---------- pixeles ----------
                    when Q_PIXELES =>
                        if esperando = '1' then
                            -- esperando a que el SPI termine el pixel anterior
                            if tx_fin = '1' then
                                esperando <= '0';
                                fase <= 0;
                                if px = 175 then
                                    px <= 0;
                                    if py = 219 then
                                        seq <= Q_VENTANA;          -- cuadro terminado
                                    else
                                        py <= py + 1;
                                    end if;
                                else
                                    px <= px + 1;
                                end if;
                            end if;
                        else
                            case fase is
                                when 0 =>
                                    -- direccion en la imagen (media resolucion)
                                    hx := px / 2;
                                    hy := py / 2;
                                    ry := hy;
                                    fondo := '0';
                                    if (e_esc = ESC_INTRO_A or e_esc = ESC_INTRO_B)
                                       and hy >= ANIM_Y0 and hy < ANIM_Y1 then
                                        ry := hy - e_reb;              -- rebote del dino
                                        if ry < ANIM_Y0 then
                                            fondo := '1';
                                        end if;
                                    end if;
                                    if ry < 0 then
                                        ry := 0;
                                    end if;
                                    rom_dir <= std_logic_vector(to_unsigned(
                                                   BASES(e_esc) + ry * P_ANCHO + hx, 17));
                                    es_fondo <= fondo;
                                    -- numero superpuesto
                                    hit := '0';
                                    dig := 0;
                                    col := 0;
                                    fila_d := hy - e_ov_y;
                                    rel := hx - e_ov_x;
                                    idx_d := 0;
                                    if e_ov_en = '1' and fila_d >= 0 and fila_d < DIG_ALTO
                                       and rel >= 0 and rel < e_ov_n * DIG_PASO then
                                        if rel < DIG_PASO then
                                            idx_d := 0; col := rel;
                                        elsif rel < 2 * DIG_PASO then
                                            idx_d := 1; col := rel - DIG_PASO;
                                        else
                                            idx_d := 2; col := rel - 2 * DIG_PASO;
                                        end if;
                                        if col < DIG_ANCHO then
                                            hit := '1';
                                        end if;
                                    end if;
                                    dig := e_dig(idx_d);
                                    if hit = '1' then
                                        dig_dir <= std_logic_vector(to_unsigned(
                                                       dig * DIG_ANCHO * DIG_ALTO + fila_d * DIG_ANCHO + col, 11));
                                    end if;
                                    en_digito <= hit;
                                    fase <= 1;
                                when 1 =>
                                    fase <= 2;                         -- la ROM lee la direccion
                                when 2 =>
                                    -- elegir el color: digito encima, si no la imagen
                                    if en_digito = '1' and dig_q /= "1111" then
                                        indice := to_integer(unsigned(dig_q));
                                    elsif es_fondo = '1' then
                                        indice := 0;
                                    else
                                        indice := to_integer(unsigned(rom_q));
                                    end if;
                                    color <= PALETA(indice);
                                    fase <= 3;
                                when others =>
                                    enviar('1', color);
                            end case;
                        end if;
                end case;
            end if;
        end if;
    end process;

    listo <= listo_i;

end architecture;
