-- =====================================================================
-- escenas.vhd
-- Decide QUE imagen muestra la pantalla segun el estado de la FSM,
-- y maneja la animacion de reposo.
--
--   REPOSO sin saldo : intro (dino saluda y rebota, 3 s) -> instrucciones (5 s) -> ...
--   REPOSO con saldo : "CREDITOS" + numero de fichas
--   GIRANDO/GRACIAS  : dino feliz
--   SIN_SALDO        : dino triste + moneda
--   AGOTADO          : dino triste
--   SOBRA            : dino apenado + saldo que sobra
--   MANTENIM         : modo tecnico + total recaudado
--
-- Las imagenes estan en una ROM (pantallas.mif); aqui solo se elige el
-- numero de imagen, el desplazamiento del rebote y el numero a superponer.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.maquina_pkg.all;
use work.pantallas_pkg.all;

entity escenas is
    generic (
        T_PASO : natural := 5_000_000        -- un paso de animacion = 100 ms
    );
    port (
        clk     : in  std_logic;
        rst     : in  std_logic;
        estado  : in  t_estado;
        saldo   : in  natural range 0 to 15;
        total   : in  natural range 0 to 255;

        escena  : out natural range 0 to P_N - 1;
        rebote  : out natural range 0 to 3;          -- filas (media resolucion)
        ov_en   : out std_logic;                     -- hay numero encima
        ov_x    : out natural range 0 to P_ANCHO - 1;
        ov_y    : out natural range 0 to P_ALTO - 1;
        ov_n    : out natural range 1 to 3;          -- cantidad de digitos
        ov_d0   : out natural range 0 to 9;          -- digito de la izquierda
        ov_d1   : out natural range 0 to 9;
        ov_d2   : out natural range 0 to 9
    );
end entity;

architecture rtl of escenas is
    signal cont   : unsigned(22 downto 0) := (others => '0');
    signal t      : natural range 0 to 79 := 0;     -- pasos de 100 ms
    signal intro  : boolean;

    type t_rebote is array (0 to 7) of natural range 0 to 3;
    constant TABLA_REBOTE : t_rebote := (0, 1, 2, 3, 3, 2, 1, 0);
begin

    -- reloj de animacion: solo corre en reposo sin saldo, si no vuelve a 0
    intro <= (estado = REPOSO or estado = VERIFICAR) and saldo = 0;

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' or not intro then
                cont <= (others => '0');
                t    <= 0;
            elsif cont = T_PASO - 1 then
                cont <= (others => '0');
                if t = 79 then
                    t <= 0;
                else
                    t <= t + 1;
                end if;
            else
                cont <= cont + 1;
            end if;
        end if;
    end process;

    process(estado, saldo, total, t, intro)
    begin
        escena <= ESC_INTRO_A;
        rebote <= 0;
        ov_en  <= '0';
        ov_x   <= 0;
        ov_y   <= 0;
        ov_n   <= 2;
        ov_d0  <= saldo / 10;
        ov_d1  <= saldo mod 10;
        ov_d2  <= 0;

        case estado is
            when REPOSO | VERIFICAR =>
                if intro then
                    if t < 30 then
                        -- 3 s: el dino saluda (alterna brazo cada 400 ms) y rebota
                        if (t mod 8) < 4 then
                            escena <= ESC_INTRO_A;
                        else
                            escena <= ESC_INTRO_B;
                        end if;
                        rebote <= TABLA_REBOTE(t mod 8);
                    else
                        escena <= ESC_INSTRUCCIONES;   -- 5 s
                    end if;
                else
                    escena <= ESC_CREDITOS;
                    ov_en  <= '1';
                    ov_x   <= OV_CREDITOS_X;
                    ov_y   <= OV_CREDITOS_Y;
                end if;

            when DISPENSAR | GIRANDO | GRACIAS =>
                escena <= ESC_GRACIAS;

            when SIN_SALDO =>
                escena <= ESC_FALTAN;

            when AGOTADO =>
                escena <= ESC_AGOTADO;

            when SOBRA =>
                escena <= ESC_SOBRA;
                ov_en  <= '1';
                ov_x   <= OV_SOBRA_X;
                ov_y   <= OV_SOBRA_Y;

            when MANTENIM =>
                escena <= ESC_MANT;
                ov_en  <= '1';
                ov_x   <= OV_MANT_X;
                ov_y   <= OV_MANT_Y;
                ov_n   <= 3;
                ov_d0  <= total / 100;
                ov_d1  <= (total / 10) mod 10;
                ov_d2  <= total mod 10;
        end case;
    end process;

end architecture;
