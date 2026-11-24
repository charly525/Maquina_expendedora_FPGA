-- Testbench de entrada_ficha (tiempos reducidos para simular rapido)
-- Casos: 1) ruido corto (no cuenta)  2) ficha con rebotes (cuenta 1)
--        3) ficha atascada (cuenta 1)  4) segunda ficha (cuenta 1 mas)
library ieee;
use ieee.std_logic_1164.all;

entity tb_entrada_ficha is
end entity;

architecture tb of tb_entrada_ficha is
    signal clk     : std_logic := '0';
    signal rst     : std_logic := '1';
    signal ficha_n : std_logic := '1';
    signal pulso   : std_logic;
    signal ocupado : std_logic;
    signal cuenta  : natural := 0;
    constant T : time := 20 ns;
begin
    clk <= not clk after T / 2;

    dut: entity work.entrada_ficha
        generic map (T_MIN => 10, T_BLOQUEO => 100)
        port map (clk => clk, rst => rst, ficha_n => ficha_n,
                  pulso => pulso, ocupado => ocupado);

    process(clk)
    begin
        if rising_edge(clk) and pulso = '1' then
            cuenta <= cuenta + 1;
        end if;
    end process;

    process
    begin
        wait for 5 * T;
        rst <= '0';
        wait for 10 * T;

        -- 1) ruido de 3 ciclos: NO debe contar
        ficha_n <= '0'; wait for 3 * T; ficha_n <= '1';
        wait for 50 * T;
        assert cuenta = 0 report "ERROR: conto ruido" severity error;

        -- 2) ficha con rebotes
        ficha_n <= '0'; wait for 2 * T; ficha_n <= '1'; wait for 1 * T;
        ficha_n <= '0'; wait for 40 * T;
        ficha_n <= '1'; wait for 2 * T; ficha_n <= '0'; wait for 1 * T;
        ficha_n <= '1';
        wait for 200 * T;
        assert cuenta = 1 report "ERROR: ficha con rebotes" severity error;

        -- 3) ficha atascada encima del switch
        ficha_n <= '0'; wait for 500 * T;
        ficha_n <= '1'; wait for 50 * T;
        assert cuenta = 2 report "ERROR: ficha atascada" severity error;

        -- 4) otra ficha normal
        ficha_n <= '0'; wait for 30 * T; ficha_n <= '1';
        wait for 200 * T;
        assert cuenta = 3 report "ERROR: segunda ficha" severity error;

        report "FIN tb_entrada_ficha: fichas contadas = " & integer'image(cuenta);
        wait;
    end process;
end architecture;
