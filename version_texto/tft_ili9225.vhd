-- =====================================================================
-- tft_ili9225.vhd
-- Controlador de la pantalla TFT 2.2" 176x220 (ILI9225) por SPI.
-- Solo ESCRIBE en la pantalla (el modulo no tiene linea de lectura).
--
-- La pantalla tiene su propia memoria de imagen (GRAM), asi que la FPGA
-- no necesita guardar la imagen: solo envia los pixeles de cada letra.
--
-- Protocolo SPI (modo 0, MSB primero, palabras de 16 bits):
--   RS = '0' -> la palabra es el NUMERO de registro (indice)
--   RS = '1' -> la palabra es un DATO (valor del registro o un pixel)
--   CS baja durante cada palabra.
--
-- Secuencia:
--   1. Reset fisico de la pantalla (RST en bajo 20 ms, espera 120 ms)
--   2. Inicializacion: lista de registros en INIT_ROM (con pausas)
--   3. Borrar toda la pantalla (color de fondo)
--   4. Bucle infinito: dibuja las 4x9 = 36 celdas de texto.
--      Cada letra 5x7 (celda 6x8) se agranda x3 -> 18x24 pixeles.
--      Como se redibuja lo mismo, no se nota parpadeo; cuando el texto
--      cambia, aparece en el siguiente barrido (~45 ms).
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tft_ili9225 is
    generic (
        DIV_SPI   : natural := 4;        -- SCK = 50 MHz / (2*4) = 6.25 MHz
        CICLOS_MS : natural := 50_000    -- ciclos de reloj en 1 ms
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        -- consulta del texto
        linea    : out natural range 0 to 3;
        columna  : out natural range 0 to 8;
        codigo   : in  std_logic_vector(5 downto 0);
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

    -- ------------------- colores (RGB565) ----------------------------
    constant C_FONDO : std_logic_vector(15 downto 0) := x"0000";   -- negro
    type t_colores is array (0 to 3) of std_logic_vector(15 downto 0);
    constant C_LINEA : t_colores := (x"FFE0", x"FFFF", x"07E0", x"07FF");
    --                               amarillo  blanco   verde    cian

    -- ------------------- geometria -----------------------------------
    constant X_MARGEN : natural := 7;    -- (176 - 9*18) / 2
    constant Y_INICIO : natural := 20;
    constant Y_PASO   : natural := 50;   -- distancia entre lineas
    constant N_PIX_TOTAL : natural := 176 * 220;

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
    signal medio     : std_logic := '0';     -- 0: palabra de indice, 1: de dato

    signal borrando  : std_logic := '1';     -- '1' = la ventana es toda la pantalla
    signal win_paso  : natural range 0 to 12 := 0;
    signal x0, x1    : unsigned(7 downto 0) := (others => '0');
    signal y0, y1    : unsigned(7 downto 0) := (others => '0');

    -- celda actual y posicion del pixel dentro de la celda
    signal lin_act   : natural range 0 to 3 := 0;
    signal col_act   : natural range 0 to 8 := 0;
    signal sx, sy    : natural range 0 to 2 := 0;   -- sub-pixel (escala x3)
    signal fx        : natural range 0 to 5 := 0;   -- columna de la letra
    signal fy        : natural range 0 to 7 := 0;   -- fila de la letra
    signal cnt_pix   : natural range 0 to N_PIX_TOTAL := 0;

    signal fy_slv    : std_logic_vector(2 downto 0);
    signal fila_bits : std_logic_vector(4 downto 0);
    signal bit_col   : std_logic;
    signal pix_on    : std_logic;
    signal listo_i   : std_logic := '0';

begin

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
    -- Pixel actual: encendido si el bit de la fuente es '1'
    -- (las columnas 5 y la fila 7 de la celda son el espacio entre letras)
    -- =================================================================
    linea   <= lin_act;
    columna <= col_act;

    fy_slv <= std_logic_vector(to_unsigned(fy, 3));

    u_fuente: entity work.fuente_5x7
        port map (
            codigo => codigo,
            fila   => fy_slv,
            bits   => fila_bits
        );

    with fx select
        bit_col <= fila_bits(4) when 0,
                   fila_bits(3) when 1,
                   fila_bits(2) when 2,
                   fila_bits(1) when 3,
                   fila_bits(0) when 4,
                   '0'          when others;   -- columna 5 = espacio

    pix_on <= bit_col when fy < 7 else '0';    -- fila 7 = espacio

    -- =================================================================
    -- Secuenciador principal
    -- =================================================================
    process(clk)
        -- envia una palabra: devuelve en 'esperando' el estado del handshake
        procedure enviar(rs : std_logic; dato : std_logic_vector(15 downto 0)) is
        begin
            tx_rs    <= rs;
            tx_dato  <= dato;
            tx_start <= '1';
            esperando <= '1';
        end procedure;
        variable reg_w : std_logic_vector(7 downto 0);
        variable val_w : std_logic_vector(15 downto 0);
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
                                    medio <= '1';          -- ya se envio el indice, falta el dato
                                else
                                    medio <= '0';
                                    if ini_idx = INIT_LEN - 1 then
                                        seq <= Q_PAUSA;    -- (no deberia pasar: la ROM termina en pausa)
                                    else
                                        ini_idx <= ini_idx + 1;
                                    end if;
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
                                    -- fin de la inicializacion: borrar pantalla
                                    listo_i  <= '1';
                                    borrando <= '1';
                                    x0 <= to_unsigned(0, 8);   x1 <= to_unsigned(175, 8);
                                    y0 <= to_unsigned(0, 8);   y1 <= to_unsigned(219, 8);
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

                    -- ---------- definir ventana + comando de escritura ----------
                    -- 6 registros (indice + dato = 12 palabras) + indice 0x22
                    when Q_VENTANA =>
                        if esperando = '1' then
                            if tx_fin = '1' then
                                esperando <= '0';
                                if win_paso = 12 then
                                    win_paso <= 0;
                                    cnt_pix  <= 0;
                                    sx <= 0; fx <= 0; sy <= 0; fy <= 0;
                                    seq      <= Q_PIXELES;
                                else
                                    win_paso <= win_paso + 1;
                                end if;
                            end if;
                        else
                            case win_paso is
                                when 0  => enviar('0', x"0036");          -- fin horizontal
                                when 1  => enviar('1', x"00" & std_logic_vector(x1));
                                when 2  => enviar('0', x"0037");          -- inicio horizontal
                                when 3  => enviar('1', x"00" & std_logic_vector(x0));
                                when 4  => enviar('0', x"0038");          -- fin vertical
                                when 5  => enviar('1', x"00" & std_logic_vector(y1));
                                when 6  => enviar('0', x"0039");          -- inicio vertical
                                when 7  => enviar('1', x"00" & std_logic_vector(y0));
                                when 8  => enviar('0', x"0020");          -- direccion x
                                when 9  => enviar('1', x"00" & std_logic_vector(x0));
                                when 10 => enviar('0', x"0021");          -- direccion y
                                when 11 => enviar('1', x"00" & std_logic_vector(y0));
                                when others => enviar('0', x"0022");      -- escribir GRAM
                            end case;
                        end if;

                    -- ---------- enviar pixeles ----------
                    when Q_PIXELES =>
                        if esperando = '1' then
                            if tx_fin = '1' then
                                esperando <= '0';
                                if borrando = '1' then
                                    -- borrado de toda la pantalla
                                    if cnt_pix = N_PIX_TOTAL - 1 then
                                        borrando <= '0';
                                        lin_act  <= 0;
                                        col_act  <= 0;
                                        x0 <= to_unsigned(X_MARGEN, 8);
                                        x1 <= to_unsigned(X_MARGEN + 17, 8);
                                        y0 <= to_unsigned(Y_INICIO, 8);
                                        y1 <= to_unsigned(Y_INICIO + 23, 8);
                                        seq <= Q_VENTANA;
                                    else
                                        cnt_pix <= cnt_pix + 1;
                                    end if;
                                else
                                    -- avanzar dentro de la celda (18 x 24 pixeles)
                                    if sx < 2 then
                                        sx <= sx + 1;
                                    else
                                        sx <= 0;
                                        if fx < 5 then
                                            fx <= fx + 1;
                                        else
                                            fx <= 0;
                                            -- fin de una fila de pixeles
                                            if sy < 2 then
                                                sy <= sy + 1;
                                            else
                                                sy <= 0;
                                                if fy < 7 then
                                                    fy <= fy + 1;
                                                else
                                                    -- fin de la celda: pasar a la siguiente
                                                    fy <= 0;
                                                    if col_act < 8 then
                                                        col_act <= col_act + 1;
                                                        x0 <= x0 + 18;
                                                        x1 <= x1 + 18;
                                                    else
                                                        col_act <= 0;
                                                        x0 <= to_unsigned(X_MARGEN, 8);
                                                        x1 <= to_unsigned(X_MARGEN + 17, 8);
                                                        if lin_act < 3 then
                                                            lin_act <= lin_act + 1;
                                                            y0 <= y0 + Y_PASO;
                                                            y1 <= y1 + Y_PASO;
                                                        else
                                                            lin_act <= 0;
                                                            y0 <= to_unsigned(Y_INICIO, 8);
                                                            y1 <= to_unsigned(Y_INICIO + 23, 8);
                                                        end if;
                                                    end if;
                                                    seq <= Q_VENTANA;
                                                end if;
                                            end if;
                                        end if;
                                    end if;
                                end if;
                            end if;
                        else
                            if borrando = '1' then
                                enviar('1', C_FONDO);
                            elsif pix_on = '1' then
                                enviar('1', C_LINEA(lin_act));
                            else
                                enviar('1', C_FONDO);
                            end if;
                        end if;
                end case;
            end if;
        end if;
    end process;

    listo <= listo_i;

end architecture;
