-- =====================================================================
-- fsm_expendedora.vhd
-- FSM principal de la maquina expendedora + registros de saldo,
-- inventario y total recaudado.
--
-- Flujo:
--   REPOSO --(tecla 1..6)--> VERIFICAR
--   VERIFICAR --(sin inventario)--> AGOTADO   --(2 s)--> REPOSO
--   VERIFICAR --(saldo < precio)--> SIN_SALDO --(2 s)--> REPOSO
--   VERIFICAR --(ok)--> DISPENSAR --> GIRANDO --(motor termina)--> GRACIAS --(2 s)-->
--        si queda saldo: SOBRA --(5 s o tecla 1..6)--> REPOSO / VERIFICAR
--        si no:          REPOSO
--   REPOSO/SOBRA --(SW0 = 1)--> MANTENIM --(SW0 = 0)--> REPOSO
--
-- Las fichas se suman al saldo en CUALQUIER estado.
-- =====================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.maquina_pkg.all;

entity fsm_expendedora is
    generic (
        T_MSG   : natural := 100_000_000;    -- 2 s a 50 MHz
        T_SOBRA : natural := 250_000_000     -- 5 s a 50 MHz
    );
    port (
        clk           : in  std_logic;
        rst           : in  std_logic;
        ficha         : in  std_logic;                    -- pulso por ficha
        tecla_valida  : in  std_logic;
        tecla_cod     : in  std_logic_vector(3 downto 0);
        modo_mant     : in  std_logic;                    -- SW0 sincronizado
        motor_ocupado : in  std_logic;                    -- OR de los 6 motores

        iniciar_motor : out std_logic_vector(N_PROD downto 1);
        estado_o      : out t_estado;
        saldo_o       : out natural range 0 to 15;
        sel_o         : out natural range 0 to N_PROD;    -- 0 = ninguno
        precio_o      : out natural range 0 to 15;
        stock_o       : out natural range 0 to 7;
        total_o       : out natural range 0 to 255
    );
end entity;

architecture rtl of fsm_expendedora is
    signal estado : t_estado := REPOSO;
    signal saldo  : natural range 0 to 15 := 0;
    signal sel    : natural range 0 to N_PROD := 0;
    signal inv    : t_inventario := (others => INV_MAX);
    signal total  : natural range 0 to 255 := 0;
    signal timer  : unsigned(27 downto 0) := (others => '0');

    signal precio_sel : natural range 0 to 15;
    signal stock_sel  : natural range 0 to 7;
    signal tecla_int  : natural range 0 to 15;
    signal es_producto: boolean;
begin

    -- Precio e inventario del producto seleccionado (logica combinacional)
    precio_sel <= PRECIOS(sel) when sel /= 0 else 0;
    stock_sel  <= inv(sel)     when sel /= 0 else 0;

    tecla_int   <= to_integer(unsigned(tecla_cod));
    es_producto <= (tecla_int >= 1) and (tecla_int <= N_PROD);

    process(clk)
        variable v_saldo : natural range 0 to 15;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                estado <= REPOSO;
                saldo  <= 0;
                sel    <= 0;
                inv    <= (others => INV_MAX);
                total  <= 0;
                timer  <= (others => '0');
            else
                -- ---------- saldo: sumar fichas (siempre) ----------
                v_saldo := saldo;
                if ficha = '1' and v_saldo < SALDO_MAX then
                    v_saldo := v_saldo + 1;
                end if;

                -- ---------- FSM ----------
                case estado is
                    when REPOSO =>
                        sel <= 0;
                        if modo_mant = '1' then
                            estado <= MANTENIM;
                        elsif tecla_valida = '1' and es_producto then
                            sel    <= tecla_int;
                            estado <= VERIFICAR;          -- se decide al marcar el numero
                        end if;

                    when VERIFICAR =>
                        timer <= (others => '0');
                        if stock_sel = 0 then
                            estado <= AGOTADO;
                        elsif saldo < precio_sel then
                            estado <= SIN_SALDO;
                        else
                            estado <= DISPENSAR;
                        end if;

                    when DISPENSAR =>
                        -- iniciar_motor se activa en este estado (ver abajo)
                        if sel /= 0 then
                            v_saldo  := v_saldo - precio_sel;
                            inv(sel) <= inv(sel) - 1;
                            if total + precio_sel <= 255 then
                                total <= total + precio_sel;
                            end if;
                        end if;
                        estado <= GIRANDO;

                    when GIRANDO =>
                        timer <= (others => '0');
                        if motor_ocupado = '0' then
                            estado <= GRACIAS;
                        end if;

                    when GRACIAS =>
                        if timer = T_MSG - 1 then
                            timer <= (others => '0');
                            if saldo > 0 then
                                estado <= SOBRA;           -- le sobro saldo
                            else
                                estado <= REPOSO;
                            end if;
                        else
                            timer <= timer + 1;
                        end if;

                    when SIN_SALDO | AGOTADO =>
                        if timer = T_MSG - 1 then
                            estado <= REPOSO;
                        else
                            timer <= timer + 1;
                        end if;

                    when SOBRA =>
                        if modo_mant = '1' then
                            estado <= MANTENIM;
                        elsif tecla_valida = '1' and es_producto then
                            sel    <= tecla_int;
                            estado <= VERIFICAR;          -- eligio otro producto
                        elsif timer = T_SOBRA - 1 or saldo = 0 then
                            estado <= REPOSO;
                        else
                            timer <= timer + 1;
                        end if;

                    when MANTENIM =>
                        inv <= (others => INV_MAX);  -- recargar todos los espirales
                        if modo_mant = '0' then
                            estado <= REPOSO;
                        end if;
                end case;

                saldo <= v_saldo;
            end if;
        end if;
    end process;

    -- Pulso de arranque al motor del producto elegido (one-hot)
    gen_ini: for k in 1 to N_PROD generate
        iniciar_motor(k) <= '1' when (estado = DISPENSAR and sel = k) else '0';
    end generate;

    estado_o <= estado;
    saldo_o  <= saldo;
    sel_o    <= sel;
    precio_o <= precio_sel;
    stock_o  <= stock_sel;
    total_o  <= total;

end architecture;
