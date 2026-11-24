# Reloj de 50 MHz de la DE0
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]
derive_clock_uncertainty
# Entradas y salidas lentas (botones, teclado, motores, SPI a 6 MHz):
# no necesitan analisis de tiempo con respecto al reloj.
set_false_path -from [get_ports {BUTTON[*] SW[*] KP_COL[*] FICHA_N}]
set_false_path -to   [get_ports {LEDG[*] HEX*_D[*] HEX*_DP KP_FILA[*] MOTOR*[*] TFT_*}]
