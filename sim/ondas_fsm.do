# Formas de onda para el video (escena 7): compra completa en la FSM
vlib work
vcom -93 maquina_pkg.vhd pantallas_pkg.vhd entrada_ficha.vhd fsm_expendedora.vhd sim/tb_entrada_ficha.vhd sim/tb_fsm_expendedora.vhd
vsim -quiet work.tb_fsm_expendedora
add wave -noupdate -divider {Entradas}
add wave -noupdate /tb_fsm_expendedora/rst
add wave -noupdate /tb_fsm_expendedora/ficha
add wave -noupdate /tb_fsm_expendedora/tecla_valida
add wave -noupdate -radix hexadecimal /tb_fsm_expendedora/tecla_cod
add wave -noupdate -divider {FSM}
add wave -noupdate /tb_fsm_expendedora/estado
add wave -noupdate -radix unsigned /tb_fsm_expendedora/saldo
add wave -noupdate -radix unsigned /tb_fsm_expendedora/sel
add wave -noupdate -radix unsigned /tb_fsm_expendedora/precio
add wave -noupdate -radix unsigned /tb_fsm_expendedora/stock
add wave -noupdate -radix unsigned /tb_fsm_expendedora/total
add wave -noupdate -divider {Motor}
add wave -noupdate -radix binary /tb_fsm_expendedora/iniciar_motor
add wave -noupdate /tb_fsm_expendedora/motor_ocupado
configure wave -namecolwidth 190 -valuecolwidth 110 -signalnamewidth 1
run 3300 ns
wave zoom full
