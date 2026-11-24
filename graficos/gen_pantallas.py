#!/usr/bin/env python3
"""
gen_pantallas.py
Genera las pantallas de la maquina expendedora como pixel art.

- Resolucion de dibujo: 88 x 110 ("media resolucion"). La FPGA dibuja cada
  pixel como un cuadro de 2x2 en la pantalla de 176 x 220.
- 16 colores (4 bits por pixel). El color 15 es "transparente" (solo digitos).
- Salidas:
    pantallas.mif     ROM con las 9 pantallas, una tras otra
    digitos.mif       ROM con los 10 digitos grandes (12 x 16)
    pantallas_pkg.vhd paleta, direcciones base y posicion de los numeros
    preview_*.png     vistas previas al tamano real y ampliadas
"""
from PIL import Image
import math

exec(open('glifos.py').read())   # G: letras 5x7 (mismas de la version anterior)

W, H = 88, 110

# ------------------------------------------------------------------ paleta
PAL = [
    (0xCD, 0xEB, 0xF7),  # 0  fondo azul pastel
    (0x2E, 0x2E, 0x38),  # 1  borde gris oscuro
    (0x95, 0xCD, 0xE6),  # 2  dino azul bebe
    (0x6F, 0xAF, 0xCB),  # 3  dino azul oscuro (espinas)
    (0xFF, 0xFF, 0xFF),  # 4  blanco (panza)
    (0xFF, 0xE2, 0x7A),  # 5  amarillo pastel (titulos)
    (0xF6, 0xA5, 0xB8),  # 6  rosado (mejillas)
    (0x86, 0xC8, 0xEE),  # 7  azul letra
    (0xEA, 0xF7, 0xFD),  # 8  panel claro
    (0x4F, 0xA3, 0xD9),  # 9  lagrima / gota
    (0xF5, 0xC5, 0x42),  # 10 moneda
    (0xF2, 0x7B, 0xA0),  # 11 corazon
    (0xD9, 0x9A, 0x1A),  # 12 moneda oscuro
    (0xB5, 0xDF, 0xF2),  # 13 azul fondo 2 (decoracion)
    (0x8A, 0x8A, 0x96),  # 14 gris
    (0xFF, 0x00, 0xFF),  # 15 transparente
]
BG, OUT, DINO, DINO2, WHITE, YEL, PINK, TXT, PANEL, DROP, COIN, HEART, COIN2, BG2, GRAY, TRANSP = range(16)

def rgb565(c):
    r, g, b = c
    return ((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)

# ------------------------------------------------------------------ lienzo
class Lienzo:
    def __init__(self, w=W, h=H, fondo=BG):
        self.w, self.h = w, h
        self.p = [[fondo] * w for _ in range(h)]
    def set(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c is not None:
            self.p[y][x] = c
    def get(self, x, y):
        return self.p[y][x]
    def pegar_mascara(self, mask, ox, oy, relleno, borde=OUT):
        """mask: dict (x,y)->color (o True). Dibuja borde de 1 px y luego el relleno."""
        pts = set(mask)
        if borde is not None:
            for (x, y) in pts:
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        q = (x + dx, y + dy)
                        if q not in pts:
                            self.set(ox + q[0], oy + q[1], borde)
        for (x, y), c in mask.items():
            self.set(ox + x, oy + y, relleno if c is True else c)

# ------------------------------------------------------------------ letras
ACENTOS = {'É': 'E', 'Á': 'A', 'Í': 'I', 'Ó': 'O', 'Ú': 'U'}
EXTRA = {
    '¡': ["00100", "00000", "00100", "00100", "00100", "00100", "00100"],
    '?': ["01110", "10001", "00001", "00110", "00100", "00000", "00100"],
    '¿': ["00100", "00000", "00100", "01100", "10000", "10001", "01110"],
    '$': ["00100", "01111", "10100", "01110", "00101", "11110", "00100"],
}
def glifo(ch):
    """Devuelve lista de pixeles (x,y) del glifo 5x7; los acentos usan y = -2, -1."""
    pts = []
    base = ACENTOS.get(ch, ch)
    filas = EXTRA.get(base) or G.get(base) or G[' ']
    for y, fila in enumerate(filas):
        for x, b in enumerate(fila):
            if b == '1':
                pts.append((x, y))
    if ch in ACENTOS:
        pts += [(3, -2), (2, -1)]
    return pts

TITULO_ESP = {
    '!': ["00100", "00100", "00100", "00100", "00000", "00000", "00100"],
    '¡': ["00100", "00000", "00000", "00100", "00100", "00100", "00100"],
    'G': ["01110", "10001", "10000", "10000", "10011", "10001", "01111"],
}
def glifo_titulo(ch):
    if ch in TITULO_ESP:
        return [(x, y) for y, f in enumerate(TITULO_ESP[ch]) for x, b in enumerate(f) if b == '1']
    return glifo(ch)

def negrita(pts):
    s = set()
    for (x, y) in pts:
        for dx in (0, 1):
            for dy in (0, 1):
                s.add((x + dx, y + dy))
    return s

def mascara_texto(txt, fuente):
    paso = 7
    m = {}
    for i, ch in enumerate(txt):
        if fuente == 'titulo':
            pts = negrita(glifo_titulo(ch))
        else:
            pts = glifo(ch)
        for (x, y) in pts:
            m[(i * paso + x, y)] = True
    ancho = len(txt) * paso - (0 if fuente == 'titulo' else 2)
    return m, ancho

def texto(L, txt, y, fuente='cuerpo', color=TXT, x=None):
    m, ancho = mascara_texto(txt, fuente)
    if x is None:
        x = (W - ancho) // 2
    L.pegar_mascara(m, x, y, color)

# ------------------------------------------------------------------ dinosaurio
def dino(pose='saluda'):
    """Dinosaurio 46 x 42. pose: saluda, quieto, feliz, triste, disculpa, brazos_arriba"""
    S = Lienzo(46, 42, None)
    cuerpo, espinas = {}, {}
    cx, cy, rx, ry = 21.0, 24.0, 16.0, 20.0
    def en_elipse(px, py, ex, ey, ax, ay):
        return ((px - ex) / ax) ** 2 + ((py - ey) / ay) ** 2 <= 1.0
    # espinas en el lomo (detras del cuerpo)
    for ang in (-62, -32, -2):
        a = math.radians(ang)
        ex, ey = cx + rx * math.cos(a) * 1.02, cy + ry * math.sin(a) * 1.02
        for y in range(42):
            for x in range(46):
                if en_elipse(x + .5, y + .5, ex, ey, 3.8, 3.8):
                    espinas[(x, y)] = DINO2
    for y in range(42):
        for x in range(46):
            px, py = x + .5, y + .5
            dentro = en_elipse(px, py, cx, cy, rx, ry) and py <= 39
            cola = en_elipse(px, py, 35, 34, 9, 5.2) and py <= 39
            if dentro or cola:
                cuerpo[(x, y)] = DINO
    # brazos
    brazos = []
    if pose in ('saluda',):
        brazos = [(4.0, 17.0, 2.6, 4.2), (36.0, 28.0, 3.2, 2.4)]
    elif pose in ('feliz', 'brazos_arriba'):
        brazos = [(4.5, 17.0, 2.6, 4.2), (37.0, 17.0, 2.6, 4.2)]
    else:
        brazos = [(5.0, 28.0, 3.2, 2.4), (36.0, 28.0, 3.2, 2.4)]
    for (ex, ey, ax, ay) in brazos:
        for y in range(42):
            for x in range(46):
                if en_elipse(x + .5, y + .5, ex, ey, ax, ay):
                    cuerpo[(x, y)] = DINO
    forma = dict(espinas)
    forma.update(cuerpo)
    S.pegar_mascara(forma, 0, 0, None)
    # panza blanca (sin borde)
    for y in range(42):
        for x in range(46):
            if (x, y) in cuerpo and en_elipse(x + .5, y + .5, 20, 30.5, 9.5, 8.5) and y <= 38:
                S.set(x, y, WHITE)
    # brazos delante de la panza: linea del brazo (como en la imagen)
    if pose not in ('saluda', 'feliz', 'brazos_arriba'):
        for (x, y) in [(8, 27), (8, 28), (9, 29), (32, 27), (32, 28), (31, 29)]:
            S.set(x, y, OUT)
    # cara
    D = OUT
    def pix(lst, c):
        for (x, y) in lst:
            S.set(x, y, c)
    mejillas = [(11, 21), (12, 21), (29, 21), (30, 21)]
    if pose in ('saluda', 'quieto', 'brazos_arriba'):
        pix([(15, 17), (15, 18), (26, 17), (26, 18)], D)                 # ojos
        pix([(18, 20), (19, 21), (20, 20), (21, 21), (22, 20)], D)       # boca w
        pix(mejillas, PINK)
    elif pose == 'feliz':
        pix([(14, 18), (15, 17), (16, 18), (25, 18), (26, 17), (27, 18)], D)   # ojos ^ ^
        pix([(18, 20), (19, 20), (20, 20), (21, 20), (22, 20), (18, 21), (22, 21), (19, 22), (20, 22), (21, 22)], D)
        pix([(19, 21), (20, 21), (21, 21)], PINK)
        pix(mejillas, PINK)
    elif pose == 'triste':
        pix([(14, 16), (15, 17), (27, 16), (26, 17)], D)                 # cejas
        pix([(15, 18), (15, 19), (26, 18), (26, 19)], D)                 # ojos
        pix([(18, 23), (19, 22), (20, 22), (21, 22), (22, 23)], D)       # boca triste
        pix([(27, 20), (27, 21), (27, 22), (28, 22), (27, 23), (28, 23)], DROP)  # lagrima
        pix([(11, 21), (12, 21)], PINK)
    elif pose == 'disculpa':
        pix([(14, 18), (15, 18), (16, 18), (25, 18), (26, 18), (27, 18)], D)   # ojos cerrados
        pix([(18, 22), (19, 21), (20, 22), (21, 21), (22, 22)], D)       # boca ~
        pix(mejillas, PINK)
        # gota de sudor en la cabeza
        gota = {(0, 0): DROP, (0, 1): DROP, (-1, 2): DROP, (0, 2): DROP, (1, 2): DROP,
                (-1, 3): DROP, (0, 3): DROP, (1, 3): DROP, (0, 4): DROP}
        S.pegar_mascara(gota, 33, 6, None)
    return S

def pegar(L, S, ox, oy):
    for y in range(S.h):
        for x in range(S.w):
            c = S.p[y][x]
            if c is not None:
                L.set(ox + x, oy + y, c)

# ------------------------------------------------------------------ iconos
def moneda(L, ox, oy, r=6):
    m = {}
    for y in range(-r, r + 1):
        for x in range(-r, r + 1):
            d = math.hypot(x, y)
            if d <= r + .3:
                m[(x, y)] = COIN2 if d > r - 1.3 else COIN
    for (x, y) in [(0, -3), (0, -2), (0, -1), (0, 0), (0, 2)]:       # "!"
        m[(x, y)] = COIN2
    m[(-3, -3)] = WHITE; m[(-2, -4)] = WHITE
    L.pegar_mascara(m, ox, oy, None)

def corazon(L, ox, oy):
    f = ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
    m = {(x, y): HEART for y, r in enumerate(f) for x, b in enumerate(r) if b == '1'}
    m[(1, 1)] = WHITE
    L.pegar_mascara(m, ox, oy, None)

def estrella(L, ox, oy):
    f = ["0001000", "0001000", "1111111", "0111110", "0011100", "0110110", "0100010"]
    m = {(x, y): YEL for y, r in enumerate(f) for x, b in enumerate(r) if b == '1'}
    L.pegar_mascara(m, ox, oy, None)

def brillo(L, ox, oy):
    for (x, y) in [(0, -2), (0, -1), (-2, 0), (-1, 0), (0, 0), (1, 0), (2, 0), (0, 1), (0, 2)]:
        L.set(ox + x, oy + y, WHITE)

def panel(L, x0, y0, x1, y1, c=PANEL):
    m = {}
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            esq = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)]
            if (x, y) in esq:
                continue
            m[(x, y)] = c
    L.pegar_mascara(m, 0, 0, None)

def decorar(L):
    """Puntitos de fondo para que no se vea plano."""
    for (x, y) in [(6, 50), (80, 44), (10, 96), (78, 100), (4, 70), (84, 74)]:
        if L.get(x, y) == BG:
            L.set(x, y, BG2)

# ------------------------------------------------------------------ escenas
OVERLAYS = {}   # escena -> (x, y, n_digitos)

def esc_intro(brazo_arriba):
    L = Lienzo()
    texto(L, "¡HOLA!", 12, 'titulo', YEL)
    pegar(L, dino('saluda' if brazo_arriba else 'quieto'), 21, 38)
    brillo(L, 14, 34); brillo(L, 74, 40); brillo(L, 70, 86)
    texto(L, "¡BIENVENIDO!", 92, 'cuerpo', TXT)
    decorar(L)
    return L

def esc_instrucciones():
    L = Lienzo()
    pegar(L, dino('saluda'), 21, 3)
    texto(L, "1.", 50, 'titulo', YEL, x=4)
    texto(L, "INGRESA", 50, 'cuerpo', TXT, x=24)
    texto(L, "LOS CRÉDITOS", 62, 'cuerpo', TXT)
    texto(L, "DEL PRODUCTO", 72, 'cuerpo', TXT)
    texto(L, "2.", 87, 'titulo', YEL, x=4)
    texto(L, "MARCA EL", 87, 'cuerpo', TXT, x=24)
    texto(L, "NÚMERO", 99, 'cuerpo', TXT)
    return L

def esc_creditos():
    L = Lienzo()
    panel(L, 14, 4, 73, 46)
    texto(L, "CRÉDITOS", 9, 'titulo', YEL)
    OVERLAYS['creditos'] = (31, 25, 2)        # 2 digitos grandes dentro del panel
    pegar(L, dino('brazos_arriba'), 21, 48)
    texto(L, "MARCA EL", 90, 'cuerpo', TXT)
    texto(L, "NÚMERO", 100, 'cuerpo', TXT)
    brillo(L, 8, 56); brillo(L, 80, 60)
    return L

def esc_faltan():
    L = Lienzo()
    texto(L, "¡FALTAN", 4, 'titulo', YEL)
    texto(L, "CRÉDITOS!", 16, 'titulo', YEL)
    pegar(L, dino('triste'), 6, 35)
    moneda(L, 68, 52)
    for (x, y) in [(58, 41), (59, 42), (77, 42), (78, 41), (59, 62), (58, 63), (77, 62), (78, 63)]:
        L.set(x, y, OUT)                       # rayitas alrededor de la moneda
    texto(L, "INGRESA MÁS", 86, 'cuerpo', TXT)
    texto(L, "CRÉDITOS", 98, 'cuerpo', TXT)
    return L

def esc_gracias():
    L = Lienzo()
    texto(L, "¡GRACIAS!", 8, 'titulo', YEL)
    pegar(L, dino('feliz'), 21, 32)
    corazon(L, 8, 34); corazon(L, 74, 30); estrella(L, 6, 58); estrella(L, 76, 56)
    corazon(L, 70, 72)
    texto(L, "¡DISFRUTA TU", 88, 'cuerpo', TXT)
    texto(L, "PRODUCTO!", 99, 'cuerpo', TXT)
    return L

def esc_sobra():
    L = Lienzo()
    texto(L, "¡UPS!", 4, 'titulo', YEL)
    texto(L, "TE SOBRA", 17, 'cuerpo', TXT)
    pegar(L, dino('disculpa'), 1, 31)
    panel(L, 50, 38, 85, 72)
    texto(L, "SALDO", 42, 'cuerpo', TXT, x=51)
    OVERLAYS['sobra'] = (55, 53, 2)
    texto(L, "ELIGE OTRO", 86, 'cuerpo', TXT)
    texto(L, "PRODUCTO", 97, 'cuerpo', TXT)
    return L

def esc_agotado():
    L = Lienzo()
    texto(L, "¡AGOTADO!", 8, 'titulo', YEL)
    pegar(L, dino('triste'), 21, 30)
    texto(L, "SE ACABÓ.", 86, 'cuerpo', TXT)
    texto(L, "ELIGE OTRO", 97, 'cuerpo', TXT)
    return L

def esc_mantenimiento():
    L = Lienzo()
    texto(L, "MODO", 4, 'titulo', YEL)
    texto(L, "TÉCNICO", 16, 'titulo', YEL)
    texto(L, "INVENTARIO", 32, 'cuerpo', TXT)
    texto(L, "RECARGADO", 42, 'cuerpo', TXT)
    panel(L, 18, 54, 69, 86)
    texto(L, "TOTAL", 58, 'cuerpo', TXT)
    OVERLAYS['mant'] = (25, 68, 3)
    texto(L, "FICHAS", 94, 'cuerpo', TXT)
    return L

ANIM_Y0, ANIM_Y1 = 30, 84
REBOTE = [0, 1, 2, 3, 3, 2, 1, 0]

ESCENAS = [
    ('intro_a', esc_intro(True)),
    ('intro_b', esc_intro(False)),
    ('instrucciones', esc_instrucciones()),
    ('creditos', esc_creditos()),
    ('faltan', esc_faltan()),
    ('gracias', esc_gracias()),
    ('sobra', esc_sobra()),
    ('agotado', esc_agotado()),
    ('mant', esc_mantenimiento()),
]

# ------------------------------------------------------------------ digitos grandes 12 x 16
DW, DH, DPASO = 12, 16, 13
def digito_grande(d):
    S = Lienzo(DW, DH, TRANSP)
    m = {}
    for (x, y) in glifo(str(d)):
        for dx in (0, 1):
            for dy in (0, 1):
                m[(1 + 2 * x + dx, 1 + 2 * y + dy)] = YEL
    S.pegar_mascara(m, 0, 0, None)
    return S
DIGITOS = [digito_grande(d) for d in range(10)]

def superponer(L, ov, valor):
    x0, y0, n = ov
    s = str(valor).rjust(n, '0')[-n:]
    for i, ch in enumerate(s):
        D = DIGITOS[int(ch)]
        for y in range(DH):
            for x in range(DW):
                c = D.p[y][x]
                if c != TRANSP:
                    L.set(x0 + i * DPASO + x, y0 + y, c)

# ------------------------------------------------------------------ salidas
def a_png(L, escala, nombre, ov=None, valor=None):
    import copy
    L2 = copy.deepcopy(L)
    if ov:
        superponer(L2, ov, valor)
    im = Image.new('RGB', (W, H))
    im.putdata([PAL[c] for fila in L2.p for c in fila])
    im = im.resize((W * escala, H * escala), Image.NEAREST)
    if nombre:
        im.save(nombre)
    return im

if __name__ == '__main__':
    import sys
    # hoja de vista previa (x3 sobre el tamano real de la pantalla)
    ej = {'creditos': 5, 'sobra': 2, 'mant': 37}
    hojas = []
    for nombre, L in ESCENAS:
        ov = OVERLAYS.get(nombre)
        hojas.append(a_png(L, 4, None, ov, ej.get(nombre)))
    sep = 16
    hoja = Image.new('RGB', (5 * (W * 4 + sep) + sep, 2 * (H * 4 + sep) + sep), (40, 40, 48))
    for i, im in enumerate(hojas):
        hoja.paste(im, (sep + (i % 5) * (W * 4 + sep), sep + (i // 5) * (H * 4 + sep)))
    hoja.save('preview_hoja.png')

    # ---- MIF de pantallas
    TAM = W * H
    datos = []
    for _, L in ESCENAS:
        for fila in L.p:
            datos += fila
    def escribir_mif(nombre, datos, ancho=4):
        with open(nombre, 'w') as f:
            f.write(f"WIDTH={ancho};\nDEPTH={len(datos)};\nADDRESS_RADIX=UNS;\nDATA_RADIX=UNS;\nCONTENT BEGIN\n")
            i = 0
            while i < len(datos):
                j = i
                while j + 1 < len(datos) and datos[j + 1] == datos[i]:
                    j += 1
                if j > i:
                    f.write(f"\t[{i}..{j}] : {datos[i]};\n")
                else:
                    f.write(f"\t{i} : {datos[i]};\n")
                i = j + 1
            f.write("END;\n")
    escribir_mif('pantallas.mif', datos)
    dig = []
    for D in DIGITOS:
        for fila in D.p:
            dig += fila
    escribir_mif('digitos.mif', dig)

    # ---- paquete VHDL
    idx = {n: i for i, (n, _) in enumerate(ESCENAS)}
    with open('pantallas_pkg.vhd', 'w') as f:
        f.write("-- GENERADO por gen_pantallas.py: no editar a mano\n")
        f.write("library ieee;\nuse ieee.std_logic_1164.all;\n\npackage pantallas_pkg is\n")
        f.write(f"    constant P_ANCHO   : natural := {W};    -- media resolucion\n")
        f.write(f"    constant P_ALTO    : natural := {H};\n")
        f.write(f"    constant P_TAM     : natural := {TAM};\n")
        f.write(f"    constant P_N       : natural := {len(ESCENAS)};\n")
        f.write(f"    constant ROM_PROF  : natural := {len(datos)};\n")
        f.write(f"    constant DIG_ANCHO : natural := {DW};\n    constant DIG_ALTO  : natural := {DH};\n    constant DIG_PASO  : natural := {DPASO};\n")
        for n, i in idx.items():
            f.write(f"    constant ESC_{n.upper():<14}: natural := {i};\n")
        f.write("    type t_paleta is array (0 to 15) of std_logic_vector(15 downto 0);\n")
        f.write("    constant PALETA : t_paleta := (\n")
        f.write(",\n".join(f"        x\"{rgb565(c):04X}\"" for c in PAL))
        f.write("\n    );\n")
        f.write("    -- posicion (media resolucion) y cantidad de digitos de cada numero\n")
        for n in ('creditos', 'sobra', 'mant'):
            x, y, k = OVERLAYS[n]
            f.write(f"    constant OV_{n.upper()}_X : natural := {x};\n    constant OV_{n.upper()}_Y : natural := {y};\n    constant OV_{n.upper()}_N : natural := {k};\n")
        f.write(f"    constant ANIM_Y0 : natural := {ANIM_Y0};   -- franja que rebota en la intro\n")
        f.write(f"    constant ANIM_Y1 : natural := {ANIM_Y1};\n")
        f.write("end package;\n")
    print("ok", len(datos), "palabras;", OVERLAYS)


def rebotar(L, yoff):
    """Lo mismo que hace la FPGA: corre hacia abajo la franja ANIM_Y0..ANIM_Y1."""
    import copy
    R = copy.deepcopy(L)
    for y in range(ANIM_Y0, ANIM_Y1):
        src = y - yoff
        for x in range(W):
            R.p[y][x] = L.p[src][x] if src >= ANIM_Y0 else BG
    return R

if __name__ == '__main__':
    # animacion de reposo: intro (brazo arriba/abajo + rebote) y luego instrucciones
    frames, dur = [], []
    E = dict(ESCENAS)
    for t in range(30):                       # 3 s, un paso cada 100 ms
        esc = E['intro_a'] if (t // 4) % 2 == 0 else E['intro_b']
        frames.append(a_png(rebotar(esc, REBOTE[t % 8]), 2, None)); dur.append(100)
    frames.append(a_png(E['instrucciones'], 2, None)); dur.append(5000)
    frames[0].save('preview_reposo.gif', save_all=True, append_images=frames[1:], duration=dur, loop=0)
