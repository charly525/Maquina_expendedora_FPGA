-- Testbench de la FSM principal.
-- Secuencia: compra sin saldo -> meter fichas -> compra OK -> sobra saldo.
-- El motor se simula: tarda 20 ciclos en "girar".
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.maquina_pkg.all;

entity tb_fsm_expendedora is
end entity;

architecture tb of tb_fsm_expendedora is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal ficha, tecla_valida, modo_mant, motor_ocupado : std_logic := '0';
    signal tecla_cod : std_logic_vector(3 downto 0) := x"0";
    signal iniciar_motor : std_logic_vector(N_PROD downto 1);
    signal estado : t_estado;
    signal saldo, precio : natural range 0 to 15;
    signal sel   : natural range 0 to N_PROD;
    signal stock : natural range 0 to 7;
    signal total : natural range 0 to 255;
    constant T : time := 20 ns;
begin
    clk <= not clk after T / 2;

    dut: entity work.fsm_expendedora
        generic map (T_MSG => 10, T_SOBRA => 30)
        port map (clk => clk, rst => rst, ficha => ficha,
                  tecla_valida => tecla_valida, tecla_cod => tecla_cod,
                  modo_mant => modo_mant, motor_ocupado => motor_ocupado,
                  iniciar_motor => iniciar_motor, estado_o => estado,
                  saldo_o => saldo, sel_o => sel, precio_o => precio,
                  stock_o => stock, total_o => total);

    -- motor falso: al recibir iniciar, queda ocupado 20 ciclos
    process
    begin
        wait until rising_edge(clk) and iniciar_motor /= "000000";
        motor_ocupado <= '1';
        for i in 1 to 20 loop wait until rising_edge(clk); end loop;
        motor_ocupado <= '0';
    end process;

    process
        procedure tecla(c : std_logic_vector(3 downto 0)) is
        begin
            wait until rising_edge(clk);
            tecla_cod <= c; tecla_valida <= '1';
            wait until rising_edge(clk);
            tecla_valida <= '0';
            wait for 5 * T;
        end procedure;
        procedure meter_ficha is
        begin
            wait until rising_edge(clk);
            ficha <= '1';
            wait until rising_edge(clk);
            ficha <= '0';
            wait for 5 * T;
        end procedure;
    begin
        wait for 5 * T;
        rst <= '0';
        wait for 5 * T;

        -- Producto 5 cuesta 3 fichas. Sin saldo -> SIN_SALDO
        tecla(x"5");
        assert estado = SIN_SALDO report "ERROR: debia ser SIN_SALDO" severity error;
        wait for 20 * T;                 -- vuelve a REPOSO
        assert estado = REPOSO report "ERROR: no volvio a REPOSO" severity error;

        -- meter 4 fichas y marcar el 5: compra directa, sin #
        meter_ficha; meter_ficha; meter_ficha; meter_ficha;
        assert saldo = 4 report "ERROR: saldo /= 4" severity error;
        tecla(x"5");
        assert estado = GIRANDO report "ERROR: no arranco el motor" severity error;
        wait for 45 * T;                 -- termina de girar, mensaje de gracias
        assert saldo = 1 report "ERROR: saldo final /= 1" severity error;
        assert total = 3 report "ERROR: total /= 3" severity error;
        assert estado = SOBRA report "ERROR: debia mostrar que sobra saldo" severity error;

        -- desde SOBRA puede elegir otro producto (el 1 cuesta 1 ficha)
        tecla(x"1");
        wait for 40 * T;
        assert saldo = 0 report "ERROR: no compro el segundo producto" severity error;
        assert estado = REPOSO report "ERROR: sin saldo debia volver a REPOSO" severity error;

        report "FIN tb_fsm_expendedora";
        wait;
    end process;
end architecture;
