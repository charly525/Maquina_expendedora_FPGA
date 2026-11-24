-- GENERADO por gen_pantallas.py: no editar a mano
library ieee;
use ieee.std_logic_1164.all;

package pantallas_pkg is
    constant P_ANCHO   : natural := 88;    -- media resolucion
    constant P_ALTO    : natural := 110;
    constant P_TAM     : natural := 9680;
    constant P_N       : natural := 9;
    constant ROM_PROF  : natural := 87120;
    constant DIG_ANCHO : natural := 12;
    constant DIG_ALTO  : natural := 16;
    constant DIG_PASO  : natural := 13;
    constant ESC_INTRO_A       : natural := 0;
    constant ESC_INTRO_B       : natural := 1;
    constant ESC_INSTRUCCIONES : natural := 2;
    constant ESC_CREDITOS      : natural := 3;
    constant ESC_FALTAN        : natural := 4;
    constant ESC_GRACIAS       : natural := 5;
    constant ESC_SOBRA         : natural := 6;
    constant ESC_AGOTADO       : natural := 7;
    constant ESC_MANT          : natural := 8;
    type t_paleta is array (0 to 15) of std_logic_vector(15 downto 0);
    constant PALETA : t_paleta := (
        x"CF5E",
        x"2967",
        x"967C",
        x"6D79",
        x"FFFF",
        x"FF0F",
        x"F537",
        x"865D",
        x"EFBF",
        x"4D1B",
        x"F628",
        x"F3D4",
        x"DCC3",
        x"B6FE",
        x"8C52",
        x"F81F"
    );
    -- posicion (media resolucion) y cantidad de digitos de cada numero
    constant OV_CREDITOS_X : natural := 31;
    constant OV_CREDITOS_Y : natural := 25;
    constant OV_CREDITOS_N : natural := 2;
    constant OV_SOBRA_X : natural := 55;
    constant OV_SOBRA_Y : natural := 53;
    constant OV_SOBRA_N : natural := 2;
    constant OV_MANT_X : natural := 25;
    constant OV_MANT_Y : natural := 68;
    constant OV_MANT_N : natural := 3;
    constant ANIM_Y0 : natural := 30;   -- franja que rebota en la intro
    constant ANIM_Y1 : natural := 84;
end package;
