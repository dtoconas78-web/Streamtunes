#!/usr/bin/env python3
"""Genera los audios de demo de StreamTunes (assets/audio/demo_N.mp3).

Son melodías ORIGINALES sintetizadas acá mismo (ondas, ruido y envolventes):
no usan samples ni música de terceros, así que no tienen derechos de autor
ajenos. Cada pista es un loop sin cortes (las colas de las notas que pasan
del final se suman al principio), pensado para repetirse mientras dure la
canción en el catálogo.

Uso (necesita `lame` instalado):
    python3 tool/generar_audios_demo.py

Solo usa la biblioteca estándar de Python: es lento (unos segundos por
pista) pero no depende de nada más.
"""

import array
import math
import os
import random
import subprocess
import tempfile
import wave

FRECUENCIA = 22050  # Hz: alcanza para un demo y achica los archivos
SALIDA = os.path.join(os.path.dirname(__file__), '..', 'assets', 'audio')

# Notas: semitonos desde La 440. midi(69) = 440 Hz.
def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


# Acordes como lista de semitonos sobre la tónica.
MAYOR = (0, 4, 7)
MENOR = (0, 3, 7)
SEPTIMA = (0, 4, 7, 10)
MENOR7 = (0, 3, 7, 10)

# Cada estilo: tempo, tonalidad (midi de la tónica), progresión (grado en
# semitonos + tipo de acorde, un acorde por compás), y semilla de la melodía.
ESTILOS = [
    # 1: pop luminoso
    dict(bpm=112, tonica=60, progresion=[(0, MAYOR), (7, MAYOR), (9, MENOR), (5, MAYOR)],
         escala=(0, 2, 4, 7, 9), semilla=1, bateria='pop', onda='cuadrada'),
    # 2: balada tranquila
    dict(bpm=78, tonica=57, progresion=[(0, MENOR7), (5, MAYOR), (10, MAYOR), (7, MENOR)],
         escala=(0, 3, 5, 7, 10), semilla=2, bateria='suave', onda='seno'),
    # 3: electrónica
    dict(bpm=124, tonica=62, progresion=[(0, MENOR), (0, MENOR), (8, MAYOR), (10, MAYOR)],
         escala=(0, 3, 5, 7, 10), semilla=3, bateria='electro', onda='sierra'),
    # 4: rock de ruta
    dict(bpm=132, tonica=64, progresion=[(0, MAYOR), (5, MAYOR), (7, MAYOR), (5, MAYOR)],
         escala=(0, 2, 4, 7, 9), semilla=4, bateria='rock', onda='sierra'),
    # 5: lo-fi nocturno
    dict(bpm=86, tonica=59, progresion=[(0, MENOR7), (5, MENOR7), (10, SEPTIMA), (3, MAYOR)],
         escala=(0, 3, 5, 7, 10), semilla=5, bateria='lofi', onda='triangulo'),
    # 6: folk alegre
    dict(bpm=104, tonica=55, progresion=[(0, MAYOR), (5, MAYOR), (0, MAYOR), (7, SEPTIMA)],
         escala=(0, 2, 4, 5, 7, 9), semilla=6, bateria='pop', onda='triangulo'),
]

COMPASES = 16  # 4 vueltas de la progresión


def oscilador(onda, fase):
    f = fase % 1.0
    if onda == 'seno':
        return math.sin(2 * math.pi * f)
    if onda == 'cuadrada':
        return 0.6 if f < 0.5 else -0.6
    if onda == 'sierra':
        return 2 * f - 1
    return 4 * abs(f - 0.5) - 1  # triángulo


class Pista:
    def __init__(self, segundos):
        self.largo = int(segundos * FRECUENCIA)
        self.buf = [0.0] * self.largo

    def nota(self, inicio, dur, freq, vol, onda='seno', ataque=0.01, caida=None):
        """Suma una nota con envolvente; lo que pasa del final vuelve al inicio."""
        caida = dur if caida is None else caida
        n = int((dur + 0.15) * FRECUENCIA)
        i0 = int(inicio * FRECUENCIA)
        paso = freq / FRECUENCIA
        fase = 0.0
        for k in range(n):
            t = k / FRECUENCIA
            env = min(1.0, t / ataque) if ataque > 0 else 1.0
            if t > dur:
                env *= max(0.0, 1 - (t - dur) / 0.15)
            env *= math.exp(-3.0 * t / max(caida, 0.05))
            self.buf[(i0 + k) % self.largo] += vol * env * oscilador(onda, fase)
            fase += paso

    def bombo(self, inicio, vol=0.9):
        n = int(0.25 * FRECUENCIA)
        i0 = int(inicio * FRECUENCIA)
        fase = 0.0
        for k in range(n):
            t = k / FRECUENCIA
            freq = 50 + 90 * math.exp(-t * 30)
            fase += freq / FRECUENCIA
            self.buf[(i0 + k) % self.largo] += vol * math.exp(-t * 14) * math.sin(2 * math.pi * fase)

    def ruido(self, inicio, dur, vol, rnd, brillo=0.7):
        n = int(dur * FRECUENCIA)
        i0 = int(inicio * FRECUENCIA)
        prev = 0.0
        for k in range(n):
            t = k / FRECUENCIA
            r = rnd.uniform(-1, 1)
            # Filtro simple: más "brillo" = menos suavizado.
            prev = brillo * r + (1 - brillo) * prev
            self.buf[(i0 + k) % self.largo] += vol * math.exp(-t * 6 / dur) * prev

    def muestras(self):
        pico = max(1e-9, max(abs(x) for x in self.buf))
        escala = 0.89 / pico
        return array.array('h', (int(max(-1, min(1, x * escala)) * 32767) for x in self.buf))


def componer(estilo):
    rnd = random.Random(estilo['semilla'])
    negra = 60.0 / estilo['bpm']
    compas = 4 * negra
    pista = Pista(COMPASES * compas)
    tonica = estilo['tonica']
    prog = estilo['progresion']

    # Motivo melódico de 2 compases (8 notas) que se repite con variaciones.
    motivo = [(rnd.choice(estilo['escala']), rnd.choice((0.5, 0.5, 1.0))) for _ in range(8)]

    for c in range(COMPASES):
        t0 = c * compas
        grado, acorde = prog[c % len(prog)]
        raiz = tonica + grado

        # Bajo: raíz en negras, con la quinta en el tiempo 3.
        for tiempo in range(4):
            nota = raiz - 24 + (7 if tiempo == 2 else 0)
            pista.nota(t0 + tiempo * negra, negra * 0.9, hz(nota), 0.35, 'triangulo', caida=negra * 2)

        # Colchón de acordes (suave, todo el compás).
        for s in acorde:
            pista.nota(t0, compas * 0.95, hz(raiz - 12 + s), 0.07, 'seno', ataque=0.2, caida=compas * 3)

        # Arpegio en corcheas.
        for paso in range(8):
            s = acorde[paso % len(acorde)] + (12 if paso >= 4 else 0)
            pista.nota(t0 + paso * negra / 2, negra * 0.4, hz(raiz + s), 0.10,
                       estilo['onda'], caida=negra * 0.6)

        # Melodía: aparece desde el compás 4 (intro sin melodía).
        if c >= 4:
            t = t0
            fin = t0 + compas
            idx = (c % 2) * 4
            while t < fin - 1e-6:
                grado_m, dur = motivo[idx % len(motivo)]
                idx += 1
                dur_s = min(dur * negra, fin - t)
                octava = 12 if (c // 4) % 2 else 0
                if rnd.random() > 0.15:  # algún silencio para respirar
                    pista.nota(t, dur_s * 0.9, hz(tonica + 12 + grado_m + octava), 0.16,
                               'seno', ataque=0.02, caida=dur_s * 2)
                t += dur_s

        # Batería.
        estilo_b = estilo['bateria']
        for tiempo in range(4):
            tt = t0 + tiempo * negra
            if estilo_b in ('electro', 'rock') or tiempo in (0, 2):
                pista.bombo(tt, 0.8 if estilo_b != 'suave' else 0.5)
            if tiempo in (1, 3) and estilo_b != 'suave':
                pista.ruido(tt, 0.18, 0.35, rnd, brillo=0.5)  # redoblante
            for medio in (0, 1):
                if estilo_b == 'suave' and medio:
                    continue
                vol_h = 0.10 if estilo_b != 'lofi' else 0.07
                pista.ruido(tt + medio * negra / 2, 0.05, vol_h, rnd, brillo=0.95)  # hi-hat
    return pista


def main():
    os.makedirs(SALIDA, exist_ok=True)
    for n, estilo in enumerate(ESTILOS, start=1):
        pista = componer(estilo)
        datos = pista.muestras()
        with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as tmp:
            ruta_wav = tmp.name
        with wave.open(ruta_wav, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(FRECUENCIA)
            w.writeframes(datos.tobytes())
        destino = os.path.join(SALIDA, f'demo_{n}.mp3')
        subprocess.run(['lame', '--quiet', '-m', 'm', '-b', '80', ruta_wav, destino], check=True)
        os.remove(ruta_wav)
        print(f'{destino}: {pista.largo / FRECUENCIA:.1f} s')


if __name__ == '__main__':
    main()
