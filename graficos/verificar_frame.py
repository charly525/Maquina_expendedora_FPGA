#!/usr/bin/env python3
"""Compara el cuadro simulado en ModelSim (frame_sim.txt) con la vista previa.
Uso: python3 verificar_frame.py ../frame_sim.txt"""
import sys, os
os.chdir(os.path.dirname(os.path.abspath(__file__)))
sys.argv = sys.argv[:2]
from PIL import Image
import gen_pantallas as g

def a565(c):
    return g.rgb565(c)

ruta = sys.argv[1] if len(sys.argv) > 1 else '../frame_sim.txt'
vals = [int(x, 16) for x in open(ruta).read().split()]
assert len(vals) == 176 * 220, f"pixeles: {len(vals)}"

E = dict(g.ESCENAS)
import copy
L = copy.deepcopy(E['creditos'])
g.superponer(L, g.OVERLAYS['creditos'], 5)
esperado = [a565(g.PAL[L.p[y // 2][x // 2]]) for y in range(220) for x in range(176)]
malos = sum(1 for a, b in zip(vals, esperado) if a != b)

im = Image.new('RGB', (176, 220))
im.putdata([(((v >> 11) & 31) << 3, ((v >> 5) & 63) << 2, (v & 31) << 3) for v in vals])
im.resize((352, 440), Image.NEAREST).save('frame_sim.png')
print("pixeles distintos:", malos, "de", len(vals))
