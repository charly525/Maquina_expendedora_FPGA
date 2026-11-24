-- =====================================================================
-- teclado_4x4.vhd
-- Escaner del teclado matricial de membrana 4x4.
--
-- Distribucion de teclas y codigo que entrega (tecla_cod):
--        C1  C2  C3  C4
--   F1    1   2   3   A        A = 10
--   F2    4   5   6   B        B = 11
--   F3    7   8   9   C        C = 12
--   F4    *   0   #   D        D = 13,  * = 14,  # = 15
--
-- Filas  : salidas. La fila activa se pone en '0'; las demas en 'Z'
--          (alta impedancia) para que dos teclas presionadas a la vez
--          nunca pongan en corto dos salidas.
-- Columnas: entradas con pull-up (se activa en Quartus). Si una tecla
--          de la fila activa esta presionada, su columna lee '0'.
--
-- Cada fila se mantiene activa T_FILA ciclos (1 ms). Un barrido completo
-- dura 4 ms. Una tecla se acepta cuando se ve igual en N_ESTABLE barridos
-- seguidos (antirrebote ~20 ms) y solo se reporta UNA vez hasta que se
-- suelte.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity teclado_4x4 is
    generic (
        T_FILA    : natural := 50_000;   -- 1 ms a 50 MHz
        N_ESTABLE : natural := 5         -- barridos iguales para aceptar
    );
    port (
        clk         : in  std_logic;
        rst         : in  std_logic;
        filas       : out std_logic_vector(3 downto 0);
        columnas    : in  std_logic_vector(3 downto 0);
        tecla_valida: out std_logic;                     -- pulso de 1 ciclo
        tecla_cod   : out std_logic_vector(3 downto 0)
    );
end entity;

architecture rtl of teclado_4x4 is
    type t_mapa is array (0 to 15) of std_logic_vector(3 downto 0);
    -- indice = fila*4 + columna
    constant MAPA : t_mapa := (
        x"1", x"2", x"3", x"A",
        x"4", x"5", x"6", x"B",
        x"7", x"8", x"9", x"C",
        x"E", x"0", x"F", x"D"
    );

    signal col_s1, col_s2 : std_logic_vector(3 downto 0) := (others => '1');
    signal cont_fila  : unsigned(16 downto 0) := (others => '0');
    signal fila_act   : unsigned(1 downto 0)  := (others => '0');

    -- resultado del barrido en curso
    signal hay_tecla  : std_logic := '0';
    signal cod_barrido: std_logic_vector(3 downto 0) := (others => '0');

    -- antirrebote
    signal cod_cand   : std_logic_vector(3 downto 0) := (others => '0');
    signal cont_est   : unsigned(3 downto 0) := (others => '0');
    signal cont_libre : unsigned(3 downto 0) := (others => '0');
    signal reportada  : std_logic := '0';
begin

    -- Filas: '0' en la activa, 'Z' en las demas
    gen_filas: for i in 0 to 3 generate
        filas(i) <= '0' when fila_act = to_unsigned(i, 2) else 'Z';
    end generate;

    process(clk)
        variable col_idx : integer range 0 to 3;
        variable encontrada : std_logic;
        variable h : std_logic;
        variable c : std_logic_vector(3 downto 0);
    begin
        if rising_edge(clk) then
            -- sincronizar columnas
            col_s1 <= columnas;
            col_s2 <= col_s1;

            tecla_valida <= '0';

            if rst = '1' then
                cont_fila  <= (others => '0');
                fila_act   <= (others => '0');
                hay_tecla  <= '0';
                cont_est   <= (others => '0');
                cont_libre <= (others => '0');
                reportada  <= '0';
            elsif cont_fila = T_FILA - 1 then
                cont_fila <= (others => '0');

                -- leer columnas al final del tiempo de la fila (ya estables)
                encontrada := '0';
                col_idx := 0;
                for j in 3 downto 0 loop
                    if col_s2(j) = '0' then
                        encontrada := '1';
                        col_idx := j;
                    end if;
                end loop;

                h := hay_tecla;
                c := cod_barrido;
                if encontrada = '1' then
                    h := '1';
                    c := MAPA(to_integer(fila_act) * 4 + col_idx);
                end if;

                if fila_act = 3 then
                    -- fin de un barrido completo: evaluar
                    if h = '1' then
                        cont_libre <= (others => '0');
                        if c = cod_cand then
                            if cont_est < N_ESTABLE then
                                cont_est <= cont_est + 1;
                            elsif reportada = '0' then
                                tecla_valida <= '1';
                                tecla_cod    <= c;
                                reportada    <= '1';
                            end if;
                        else
                            cod_cand <= c;
                            cont_est <= (others => '0');
                        end if;
                    else
                        cont_est <= (others => '0');
                        if cont_libre < N_ESTABLE then
                            cont_libre <= cont_libre + 1;
                        else
                            reportada <= '0';   -- tecla suelta: rearmar
                        end if;
                    end if;
                    hay_tecla   <= '0';
                    cod_barrido <= (others => '0');
                else
                    hay_tecla   <= h;
                    cod_barrido <= c;
                end if;

                fila_act <= fila_act + 1;
            else
                cont_fila <= cont_fila + 1;
            end if;
        end if;
    end process;

end architecture;
