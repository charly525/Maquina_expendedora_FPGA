-- =====================================================================
-- textos_pantalla.vhd
-- Decide QUE texto se ve en la pantalla TFT segun el estado de la FSM.
-- La pantalla tiene 4 lineas de 9 caracteres.
-- El controlador de la TFT pregunta (linea, columna) y este modulo
-- responde con el codigo del caracter (ver fuente_5x7.vhd).
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.maquina_pkg.all;

entity textos_pantalla is
    port (
        estado  : in  t_estado;
        saldo   : in  natural range 0 to 15;
        sel     : in  natural range 0 to N_PROD;
        precio  : in  natural range 0 to 15;
        total   : in  natural range 0 to 255;
        linea   : in  natural range 0 to 3;
        columna : in  natural range 0 to 8;
        codigo  : out std_logic_vector(5 downto 0)
    );
end entity;

architecture rtl of textos_pantalla is
    subtype t_car is natural range 0 to 63;
    type t_linea    is array (0 to 8) of t_car;
    type t_pantalla is array (0 to 3) of t_linea;

    -- caracter ASCII -> codigo de la fuente
    function cc(c : character) return t_car is
    begin
        case c is
            when '0' to '9' => return character'pos(c) - character'pos('0');
            when 'A' to 'Z' => return character'pos(c) - character'pos('A') + 10;
            when ':' => return 37;
            when '-' => return 38;
            when '!' => return 39;
            when '.' => return 40;
            when '#' => return 41;
            when '*' => return 42;
            when others => return 36;   -- espacio
        end case;
    end function;

    -- texto de 9 caracteres -> linea
    function lin(s : string(1 to 9)) return t_linea is
        variable r : t_linea;
    begin
        for i in 0 to 8 loop
            r(i) := cc(s(i + 1));
        end loop;
        return r;
    end function;

    signal p : t_pantalla;
begin

    process(estado, saldo, sel, precio, total)
        variable v : t_pantalla;
        variable falta : natural range 0 to 15;
    begin
        -- linea de saldo, usada en varios estados: "SALDO: dd"
        v(2) := lin("SALDO: 00");
        v(2)(7) := saldo / 10;
        v(2)(8) := saldo mod 10;

        case estado is
            when REPOSO =>
                v(0) := lin("INSERTE  ");
                v(1) := lin("FICHAS   ");
                v(3) := lin("ELIJA 1-6");

            when SELECCION =>
                v(0) := lin("PROD: 0  ");
                v(0)(6) := sel;
                v(1) := lin("PRECIO: 0");
                v(1)(8) := precio;
                v(3) := lin("#SI  *NO ");

            when VERIFICAR | DISPENSAR | GIRANDO =>
                v(0) := lin("PROD: 0  ");
                v(0)(6) := sel;
                v(1) := lin("ESPERE...");
                v(3) := lin("         ");

            when GRACIAS =>
                v(0) := lin("GRACIAS! ");
                v(1) := lin("RETIRE SU");
                v(3) := lin("PRODUCTO ");

            when SIN_SALDO =>
                if precio > saldo then
                    falta := precio - saldo;
                else
                    falta := 0;
                end if;
                v(0) := lin("SIN SALDO");
                v(1) := lin("FALTAN:00");
                v(1)(7) := falta / 10;
                v(1)(8) := falta mod 10;
                v(3) := lin("INSERTE  ");

            when AGOTADO =>
                v(0) := lin("PROD: 0  ");
                v(0)(6) := sel;
                v(1) := lin("AGOTADO! ");
                v(3) := lin("ELIJA 1-6");

            when MANTENIM =>
                v(0) := lin("MANTENIM.");
                v(1) := lin("RECARGADO");
                v(2) := lin("TOTAL:000");
                v(2)(6) := total / 100;
                v(2)(7) := (total / 10) mod 10;
                v(2)(8) := total mod 10;
                v(3) := lin("FICHAS   ");
        end case;
        p <= v;
    end process;

    codigo <= std_logic_vector(to_unsigned(p(linea)(columna), 6));

end architecture;
