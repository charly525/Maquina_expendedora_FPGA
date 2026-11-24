#!/usr/bin/env python3
# Genera maquina_expendedora.qsf y una tabla de conexiones (para la guia)
# a partir de UNA sola lista, para que nunca se contradigan.
# Pines FPGA tomados del DE0 User Manual (Terasic).

# (puerto VHDL, pin FPGA, conector, pin fisico del conector, senal DE0, destino)
EXT = [
    # ---- GPIO_0 (J4) ----
    ("KP_FILA[0]", "AB16", "GPIO_0", 2,  "GPIO0_D0",  "Teclado pin 1 (fila 1)"),
    ("KP_FILA[1]", "AA16", "GPIO_0", 4,  "GPIO0_D1",  "Teclado pin 2 (fila 2)"),
    ("KP_FILA[2]", "AA15", "GPIO_0", 5,  "GPIO0_D2",  "Teclado pin 3 (fila 3)"),
    ("KP_FILA[3]", "AB15", "GPIO_0", 6,  "GPIO0_D3",  "Teclado pin 4 (fila 4)"),
    ("KP_COL[0]",  "AA14", "GPIO_0", 7,  "GPIO0_D4",  "Teclado pin 5 (columna 1)"),
    ("KP_COL[1]",  "AB14", "GPIO_0", 8,  "GPIO0_D5",  "Teclado pin 6 (columna 2)"),
    ("KP_COL[2]",  "AB13", "GPIO_0", 9,  "GPIO0_D6",  "Teclado pin 7 (columna 3)"),
    ("KP_COL[3]",  "AA13", "GPIO_0", 10, "GPIO0_D7",  "Teclado pin 8 (columna 4)"),
    ("FICHA_N",    "AB10", "GPIO_0", 13, "GPIO0_D8",  "Microswitch de la ficha (terminal NO)"),
    ("TFT_CS",     "AA10", "GPIO_0", 14, "GPIO0_D9",  "TFT CS"),
    ("TFT_RS",     "AB8",  "GPIO_0", 15, "GPIO0_D10", "TFT RS"),
    ("TFT_RST",    "AA8",  "GPIO_0", 16, "GPIO0_D11", "TFT RST"),
    ("TFT_SCK",    "AB5",  "GPIO_0", 17, "GPIO0_D12", "TFT CLK"),
    ("TFT_SDI",    "AA5",  "GPIO_0", 18, "GPIO0_D13", "TFT SDI"),
    # ---- GPIO_1 (J5): motores. Se salta el pin 20 (D14) porque muchos
    #      cables IDE de 40 hilos traen ese agujero tapado. ----
    ("MOTOR1[0]", "AA20", "GPIO_1", 2,  "GPIO1_D0",  "ULN2003 #1 IN1"),
    ("MOTOR1[1]", "AB20", "GPIO_1", 4,  "GPIO1_D1",  "ULN2003 #1 IN2"),
    ("MOTOR1[2]", "AA19", "GPIO_1", 5,  "GPIO1_D2",  "ULN2003 #1 IN3"),
    ("MOTOR1[3]", "AB19", "GPIO_1", 6,  "GPIO1_D3",  "ULN2003 #1 IN4"),
    ("MOTOR2[0]", "AB18", "GPIO_1", 7,  "GPIO1_D4",  "ULN2003 #2 IN1"),
    ("MOTOR2[1]", "AA18", "GPIO_1", 8,  "GPIO1_D5",  "ULN2003 #2 IN2"),
    ("MOTOR2[2]", "AA17", "GPIO_1", 9,  "GPIO1_D6",  "ULN2003 #2 IN3"),
    ("MOTOR2[3]", "AB17", "GPIO_1", 10, "GPIO1_D7",  "ULN2003 #2 IN4"),
    ("MOTOR3[0]", "Y17",  "GPIO_1", 13, "GPIO1_D8",  "ULN2003 #3 IN1"),
    ("MOTOR3[1]", "W17",  "GPIO_1", 14, "GPIO1_D9",  "ULN2003 #3 IN2"),
    ("MOTOR3[2]", "U15",  "GPIO_1", 15, "GPIO1_D10", "ULN2003 #3 IN3"),
    ("MOTOR3[3]", "T15",  "GPIO_1", 16, "GPIO1_D11", "ULN2003 #3 IN4"),
    ("MOTOR4[0]", "W15",  "GPIO_1", 17, "GPIO1_D12", "ULN2003 #4 IN1"),
    ("MOTOR4[1]", "V15",  "GPIO_1", 18, "GPIO1_D13", "ULN2003 #4 IN2"),
    ("MOTOR4[2]", "AA9",  "GPIO_1", 22, "GPIO1_D15", "ULN2003 #4 IN3"),
    ("MOTOR4[3]", "AA7",  "GPIO_1", 23, "GPIO1_D16", "ULN2003 #4 IN4"),
    ("MOTOR5[0]", "AB7",  "GPIO_1", 24, "GPIO1_D17", "ULN2003 #5 IN1"),
    ("MOTOR5[1]", "T14",  "GPIO_1", 25, "GPIO1_D18", "ULN2003 #5 IN2"),
    ("MOTOR5[2]", "R14",  "GPIO_1", 26, "GPIO1_D19", "ULN2003 #5 IN3"),
    ("MOTOR5[3]", "U12",  "GPIO_1", 27, "GPIO1_D20", "ULN2003 #5 IN4"),
    ("MOTOR6[0]", "T12",  "GPIO_1", 28, "GPIO1_D21", "ULN2003 #6 IN1"),
    ("MOTOR6[1]", "R11",  "GPIO_1", 31, "GPIO1_D22", "ULN2003 #6 IN2"),
    ("MOTOR6[2]", "R12",  "GPIO_1", 32, "GPIO1_D23", "ULN2003 #6 IN3"),
    ("MOTOR6[3]", "U10",  "GPIO_1", 33, "GPIO1_D24", "ULN2003 #6 IN4"),
]

PLACA = [("CLOCK_50", "G21")]
PLACA += [(f"BUTTON[{i}]", p) for i, p in enumerate(["H2", "G3", "F1"])]
PLACA += [(f"SW[{i}]", p) for i, p in enumerate(
    ["J6", "H5", "H6", "G4", "G5", "J7", "H7", "E3", "E4", "D2"])]
PLACA += [(f"LEDG[{i}]", p) for i, p in enumerate(
    ["J1", "J2", "J3", "H1", "F2", "E1", "C1", "C2", "B2", "B1"])]
HEX = {
    0: (["E11", "F11", "H12", "H13", "G12", "F12", "F13"], "D13"),
    1: (["A13", "B13", "C13", "A14", "B14", "E14", "A15"], "B15"),
    2: (["D15", "A16", "B16", "E15", "A17", "B17", "F14"], "A18"),
    3: (["B18", "F15", "A19", "B19", "C19", "D19", "G15"], "G16"),
}
for n, (segs, dp) in HEX.items():
    PLACA += [(f"HEX{n}_D[{i}]", p) for i, p in enumerate(segs)]
    PLACA.append((f"HEX{n}_DP", dp))

# chequeos: ningun pin FPGA repetido, ningun pin fisico repetido por conector
todos = [p for _, p in PLACA] + [e[1] for e in EXT]
assert len(todos) == len(set(todos)), "pin FPGA repetido"
for con in ("GPIO_0", "GPIO_1"):
    fis = [e[3] for e in EXT if e[2] == con]
    assert len(fis) == len(set(fis)), "pin fisico repetido"
    assert not set(fis) & {1, 3, 11, 12, 19, 20, 21, 29, 30}, "pin reservado usado"

q = []
q.append("# =====================================================================")
q.append("# maquina_expendedora.qsf  - Terasic DE0 (Cyclone III EP3C16F484C6)")
q.append("# Generado por gen_pines.py")
q.append("# =====================================================================")
q.append('set_global_assignment -name FAMILY "Cyclone III"')
q.append("set_global_assignment -name DEVICE EP3C16F484C6")
q.append("set_global_assignment -name TOP_LEVEL_ENTITY maquina_expendedora")
q.append('set_global_assignment -name RESERVE_ALL_UNUSED_PINS "AS INPUT TRI-STATED"')
q.append('set_global_assignment -name STRATIX_DEVICE_IO_STANDARD "3.3-V LVTTL"')
for f in ["maquina_pkg.vhd", "pantallas_pkg.vhd", "entrada_ficha.vhd", "teclado_4x4.vhd",
          "motor_paso.vhd", "fsm_expendedora.vhd", "deco7seg.vhd", "escenas.vhd",
          "tft_ili9225.vhd", "maquina_expendedora.vhd"]:
    q.append(f"set_global_assignment -name VHDL_FILE {f}")
q.append("set_global_assignment -name SDC_FILE maquina_expendedora.sdc")
q.append("set_global_assignment -name MIF_FILE pantallas.mif")
q.append("set_global_assignment -name MIF_FILE digitos.mif")
q.append("")
q.append("# ---------------- Pines de la tarjeta ----------------")
for name, pin in PLACA:
    q.append(f"set_location_assignment PIN_{pin} -to {name}")
q.append("")
q.append("# ---------------- Conectores GPIO ----------------")
for name, pin, con, fis, sen, dest in EXT:
    q.append(f"set_location_assignment PIN_{pin} -to {name}   # {con} pin {fis} ({sen}) -> {dest}")
q.append("")
q.append("# Todos los pines a 3.3 V LVTTL")
for name, _ in PLACA:
    q.append(f'set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {name}')
for e in EXT:
    q.append(f'set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to {e[0]}')
q.append("")
q.append("# Pull-up interno en las columnas del teclado y en el switch de la ficha")
for i in range(4):
    q.append(f"set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to KP_COL[{i}]")
q.append("set_instance_assignment -name WEAK_PULL_UP_RESISTOR ON -to FICHA_N")

qsf = "\n".join(q) + "\n"
# Quartus no acepta comentarios al final de una linea de asignacion: moverlos arriba
lineas = []
for l in qsf.splitlines():
    if l.startswith("set_") and "#" in l:
        cmd, com = l.split("#", 1)
        lineas.append("#" + com)
        lineas.append(cmd.rstrip())
    else:
        lineas.append(l)
open("maquina_expendedora.qsf", "w").write("\n".join(lineas) + "\n")

# tabla para la guia (markdown)
with open("tabla_pines.md", "w") as t:
    for name, pin, con, fis, sen, dest in EXT:
        t.write(f"| {con} | {fis} | {sen} | {name} | {dest} |\n")
print("OK", len(PLACA), "pines placa,", len(EXT), "pines GPIO")
