-- =====================================================================
-- entrada_ficha.vhd
-- Detecta la caida de UNA ficha sobre el microswitch.
--
-- El switch va entre el pin y GND, con pull-up: reposo = '1',
-- ficha presionando = '0'.
--
-- Funcionamiento (FSM de 4 estados):
--   ESPERA    : entrada en '1'. Si baja a '0' -> CONFIRMA.
--   CONFIRMA  : la entrada debe quedarse en '0' durante T_MIN ciclos
--               (filtra ruido de los motores). Si sube antes -> ESPERA.
--               Si se cumple -> genera pulso de 1 ciclo y pasa a BLOQUEO.
--   BLOQUEO   : ignora la entrada durante T_BLOQUEO ciclos
--               (los rebotes del switch no cuentan como fichas nuevas).
--   SOLTAR    : espera a que la entrada vuelva a '1' (por si la ficha
--               quedo atascada encima del switch, solo cuenta una vez).
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity entrada_ficha is
    generic (
        T_MIN     : natural := 25_000;      -- 0.5 ms a 50 MHz
        T_BLOQUEO : natural := 15_000_000   -- 300 ms a 50 MHz
    );
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;           -- activo en alto
        ficha_n  : in  std_logic;           -- pin del switch (activo en bajo)
        pulso    : out std_logic;           -- '1' durante 1 ciclo por ficha
        ocupado  : out std_logic            -- '1' mientras esta bloqueado (para un LED)
    );
end entity;

architecture rtl of entrada_ficha is
    type t_estado is (ESPERA, CONFIRMA, BLOQUEO, SOLTAR);
    signal estado : t_estado := ESPERA;

    -- Sincronizador de 2 flip-flops (evita metaestabilidad)
    signal sync1, sync2 : std_logic := '1';

    signal cont : unsigned(23 downto 0) := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            sync1 <= ficha_n;
            sync2 <= sync1;
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            pulso <= '0';
            if rst = '1' then
                estado <= ESPERA;
                cont   <= (others => '0');
            else
                case estado is
                    when ESPERA =>
                        cont <= (others => '0');
                        if sync2 = '0' then
                            estado <= CONFIRMA;
                        end if;

                    when CONFIRMA =>
                        if sync2 = '1' then
                            estado <= ESPERA;           -- era ruido
                        elsif cont = T_MIN - 1 then
                            pulso  <= '1';              -- ficha valida
                            cont   <= (others => '0');
                            estado <= BLOQUEO;
                        else
                            cont <= cont + 1;
                        end if;

                    when BLOQUEO =>
                        if cont = T_BLOQUEO - 1 then
                            estado <= SOLTAR;
                        else
                            cont <= cont + 1;
                        end if;

                    when SOLTAR =>
                        if sync2 = '1' then
                            estado <= ESPERA;
                        end if;
                end case;
            end if;
        end if;
    end process;

    ocupado <= '0' when estado = ESPERA else '1';

end architecture;
