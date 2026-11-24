-- =====================================================================
-- deco7seg.vhd
-- Decodificador para un display de 7 segmentos de la DE0.
-- Los displays de la DE0 son ACTIVOS EN BAJO ('0' enciende el segmento).
--
-- Entrada (5 bits):
--   0..15 -> 0 1 2 3 4 5 6 7 8 9 A b C d E F
--   16    -> apagado
--   17    -> guion  "-"
--   18    -> letra  "P"
--   19    -> letra  "r"
-- Salida seg(6 downto 0) = g f e d c b a  (seg(0) = segmento a)
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;

entity deco7seg is
    port (
        valor : in  std_logic_vector(4 downto 0);
        seg   : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of deco7seg is
    signal on_seg : std_logic_vector(6 downto 0);   -- activo en alto
begin
    with valor select
        on_seg <= "0111111" when "00000",   -- 0
                  "0000110" when "00001",   -- 1
                  "1011011" when "00010",   -- 2
                  "1001111" when "00011",   -- 3
                  "1100110" when "00100",   -- 4
                  "1101101" when "00101",   -- 5
                  "1111101" when "00110",   -- 6
                  "0000111" when "00111",   -- 7
                  "1111111" when "01000",   -- 8
                  "1101111" when "01001",   -- 9
                  "1110111" when "01010",   -- A
                  "1111100" when "01011",   -- b
                  "0111001" when "01100",   -- C
                  "1011110" when "01101",   -- d
                  "1111001" when "01110",   -- E
                  "1110001" when "01111",   -- F
                  "0000000" when "10000",   -- apagado
                  "1000000" when "10001",   -- -
                  "1110011" when "10010",   -- P
                  "1010000" when "10011",   -- r
                  "0000000" when others;

    seg <= not on_seg;   -- la DE0 enciende con '0'
end architecture;
