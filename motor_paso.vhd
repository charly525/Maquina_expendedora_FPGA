-- =====================================================================
-- motor_paso.vhd
-- Controla UN motor 28BYJ-48 a traves de su driver ULN2003.
-- Se instancia 6 veces en el top (una por espiral).
--
-- Secuencia de paso completo con dos bobinas encendidas (mas torque):
--   paso 0: IN1 IN2 IN3 IN4 = 1 1 0 0
--   paso 1:                   0 1 1 0
--   paso 2:                   0 0 1 1
--   paso 3:                   1 0 0 1
--
-- Al recibir 'iniciar' (pulso), da N_PASOS pasos, uno cada T_PASO ciclos,
-- y luego apaga las 4 bobinas (fases = "0000") para no calentar el motor
-- ni gastar corriente. La caja reductora mantiene la posicion sola.
--
-- 2048 pasos completos = 1 vuelta del eje de salida.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity motor_paso is
    generic (
        N_PASOS  : natural := 2048;      -- 1 vuelta del espiral
        T_PASO   : natural := 150_000;   -- 3 ms por paso a 50 MHz (~6 s/vuelta)
        SENTIDO  : std_logic := '0'      -- '0' o '1': invierte el giro
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        iniciar : in  std_logic;
        fases   : out std_logic_vector(3 downto 0);   -- IN4 IN3 IN2 IN1
        ocupado : out std_logic
    );
end entity;

architecture rtl of motor_paso is
    type t_estado is (QUIETO, GIRANDO);
    signal estado     : t_estado := QUIETO;
    signal cont_t     : unsigned(19 downto 0) := (others => '0');
    signal cont_pasos : unsigned(15 downto 0) := (others => '0');
    signal paso       : unsigned(1 downto 0)  := (others => '0');
begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                estado     <= QUIETO;
                cont_t     <= (others => '0');
                cont_pasos <= (others => '0');
            else
                case estado is
                    when QUIETO =>
                        cont_t     <= (others => '0');
                        cont_pasos <= (others => '0');
                        if iniciar = '1' then
                            estado <= GIRANDO;
                        end if;

                    when GIRANDO =>
                        if cont_t = T_PASO - 1 then
                            cont_t <= (others => '0');
                            -- avanzar al siguiente paso de la secuencia
                            if SENTIDO = '0' then
                                paso <= paso + 1;
                            else
                                paso <= paso - 1;
                            end if;
                            if cont_pasos = N_PASOS - 1 then
                                estado <= QUIETO;
                            else
                                cont_pasos <= cont_pasos + 1;
                            end if;
                        else
                            cont_t <= cont_t + 1;
                        end if;
                end case;
            end if;
        end if;
    end process;

    -- Decodificador: numero de paso -> bobinas encendidas.
    -- Bits: fases(0)=IN1, fases(1)=IN2, fases(2)=IN3, fases(3)=IN4
    process(estado, paso)
    begin
        if estado = QUIETO then
            fases <= "0000";
        else
            case paso is
                when "00"   => fases <= "0011";   -- IN1 IN2
                when "01"   => fases <= "0110";   -- IN2 IN3
                when "10"   => fases <= "1100";   -- IN3 IN4
                when others => fases <= "1001";   -- IN4 IN1
            end case;
        end if;
    end process;

    ocupado <= '1' when estado = GIRANDO else '0';

end architecture;
