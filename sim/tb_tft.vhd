-- Testbench del controlador de pantalla.
-- Simula la pantalla: escucha el SPI, y cuando llegan los pixeles los
-- escribe en "frame_sim.txt" (un valor RGB565 en hexadecimal por linea).
-- Luego graficos/verificar_frame.py lo convierte en imagen y lo compara
-- con la vista previa.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use work.pantallas_pkg.all;

entity tb_tft is
end entity;

architecture tb of tb_tft is
    signal clk : std_logic := '0';
    signal rst : std_logic := '1';
    signal cs, rs, rstn, sck, sdi, listo : std_logic;
    constant T : time := 20 ns;
    signal fin : boolean := false;
begin
    clk <= not clk after T / 2 when not fin;

    dut: entity work.tft_ili9225
        generic map (DIV_SPI => 1, CICLOS_MS => 2)
        port map (clk => clk, rst => rst,
                  escena => ESC_CREDITOS, rebote => 0,
                  ov_en => '1', ov_x => OV_CREDITOS_X, ov_y => OV_CREDITOS_Y, ov_n => 2,
                  ov_d0 => 0, ov_d1 => 5, ov_d2 => 0,
                  tft_cs => cs, tft_rs => rs, tft_rst => rstn,
                  tft_sck => sck, tft_sdi => sdi, listo => listo);

    rst <= '0' after 5 * T;

    -- "pantalla": recibe palabras de 16 bits
    process
        variable palabra : std_logic_vector(15 downto 0);
        variable nbits   : natural := 0;
        variable gram    : boolean := false;
        variable npix    : natural := 0;
        file f           : text open write_mode is "frame_sim.txt";
        variable l       : line;
    begin
        wait until rising_edge(sck) or rising_edge(cs);
        if cs = '1' then
            nbits := 0;
        else
            palabra := palabra(14 downto 0) & sdi;
            nbits := nbits + 1;
            if nbits = 16 then
                nbits := 0;
                if rs = '0' then
                    gram := (palabra = x"0022");
                elsif gram then
                    hwrite(l, palabra);
                    writeline(f, l);
                    npix := npix + 1;
                    if npix = 176 * 220 then
                        report "FIN tb_tft: cuadro completo capturado";
                        fin <= true;
                        wait;
                    end if;
                end if;
            end if;
        end if;
    end process;
end architecture;
