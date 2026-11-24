# Simulaciones de la maquina expendedora (ModelSim-Altera)
# Uso, desde la consola de ModelSim:
#   cd {C:/Users/Caro/Desktop/entrega proyecto digitales/maquina_vhdl}
#   do sim/correr_sim.do
vlib work
vcom -93 maquina_pkg.vhd pantallas_pkg.vhd entrada_ficha.vhd fsm_expendedora.vhd tft_ili9225.vhd sim/tb_entrada_ficha.vhd sim/tb_fsm_expendedora.vhd sim/tb_tft.vhd

echo "===== tb_entrada_ficha ====="
vsim -quiet work.tb_entrada_ficha
run 30 us
quit -sim

echo "===== tb_fsm_expendedora ====="
vsim -quiet work.tb_fsm_expendedora
run 30 us
quit -sim

echo "===== tb_tft (un cuadro completo, tarda un poco) ====="
vsim -quiet work.tb_tft
run -all
quit -sim

write transcript sim_log.txt
echo "===== LISTO ====="
