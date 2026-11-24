# Formas de onda para el video (escena 7): antirrebote de la ficha
vsim -quiet work.tb_entrada_ficha
add wave -noupdate /tb_entrada_ficha/rst
add wave -noupdate /tb_entrada_ficha/ficha_n
add wave -noupdate /tb_entrada_ficha/dut/estado
add wave -noupdate /tb_entrada_ficha/pulso
add wave -noupdate /tb_entrada_ficha/ocupado
add wave -noupdate -radix unsigned /tb_entrada_ficha/cuenta
configure wave -namecolwidth 190 -valuecolwidth 110 -signalnamewidth 1
run 22000 ns
wave zoom full
