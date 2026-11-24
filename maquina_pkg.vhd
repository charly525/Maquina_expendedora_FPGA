-- =====================================================================
-- maquina_pkg.vhd
-- Constantes y tipos compartidos por todos los modulos.
-- Para cambiar precios o inventario inicial, solo editen este archivo.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package maquina_pkg is

    constant N_PROD  : natural := 6;    -- productos = motores = espirales
    constant INV_MAX : natural := 5;    -- unidades por espiral al recargar
    constant SALDO_MAX : natural := 15; -- tope del contador de fichas

    -- Precio de cada producto, EN FICHAS (producto 1 .. producto 6)
    type t_precios is array (1 to N_PROD) of natural range 0 to 15;
    constant PRECIOS : t_precios := (1, 1, 2, 2, 3, 3);

    -- Sentido de giro de cada motor. Si un espiral empuja hacia atras,
    -- cambien su '0' por '1' (no hace falta recablear).
    type t_sentidos is array (1 to N_PROD) of std_logic;
    constant SENTIDOS : t_sentidos := ('0', '0', '0', '0', '0', '0');

    -- Inventario de cada espiral
    type t_inventario is array (1 to N_PROD) of natural range 0 to 7;

    -- Estados de la FSM principal (los usan tambien las pantallas)
    type t_estado is (
        REPOSO,      -- animacion del dino / creditos disponibles
        VERIFICAR,   -- revisa saldo e inventario del producto marcado
        DISPENSAR,   -- arranca el motor y descuenta (1 ciclo)
        GIRANDO,     -- espera a que el motor termine la vuelta
        GRACIAS,     -- dino feliz (2 s)
        SIN_SALDO,   -- dino triste: faltan creditos (2 s)
        AGOTADO,     -- dino triste: producto agotado (2 s)
        SOBRA,       -- dino apenado: sobra saldo, elige otro (5 s o hasta una tecla)
        MANTENIM     -- SW0 arriba: recarga inventario y muestra total
    );

    -- Codigos de tecla que entrega teclado_4x4
    constant TECLA_AST : std_logic_vector(3 downto 0) := x"E";  -- *
    constant TECLA_NUM : std_logic_vector(3 downto 0) := x"F";  -- #

end package;
