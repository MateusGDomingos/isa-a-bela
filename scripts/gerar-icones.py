#!/usr/bin/env python3
"""Gera os ícones do app a partir de uma tulipa desenhada em código.

A identidade visual do Isa a Bela é o tema "Rosa Elegante" e o ícone é uma tulipa
sobre fundo rosa (seção 4 da spec). Em vez de depender de um arquivo binário que
ninguém sabe de onde veio, a tulipa é descrita aqui em coordenadas: dá para ler,
revisar num diff e regerar em qualquer tamanho.

Requer Pillow, a única dependência fora do npm neste repositório:

    pip install --user Pillow

Uso: python3 scripts/gerar-icones.py

Os PNG gerados são versionados, então rodar isto só é necessário ao mudar o desenho
ou as cores. O fundo do splash e do ícone adaptativo são definidos em app.json, não
aqui — mantenha os dois em sincronia com src/theme/tokens.ts.
"""

from PIL import Image, ImageDraw

# Tokens de src/theme/tokens.ts. Mantenha em sincronia com eles.
ROSA_FUNDO = (194, 69, 110, 255)  # colors.accent  #C2456E
BRANCO = (255, 255, 255, 255)
FOLHA = (248, 214, 226, 255)  # rosa claro: contrasta com o fundo sem competir com a flor
ZOOM = 1.20  # a flor ocupa mais do quadro; sem isso sobra margem morta no topo
SUBIR = 28  # sobe o conjunto, porque o peso visual da copa fica na metade de cima

SUPER = 4  # desenha em 4x e reduz, para ter antialiasing decente
LADO = 1024


def bezier(p0, p1, p2, passos=48):
    """Amostra uma bézier quadrática. Retorna lista de pontos."""
    saida = []
    for i in range(passos + 1):
        t = i / passos
        u = 1 - t
        x = u * u * p0[0] + 2 * u * t * p1[0] + t * t * p2[0]
        y = u * u * p0[1] + 2 * u * t * p1[1] + t * t * p2[1]
        saida.append((x, y))
    return saida


def tulipa(escala, dx=0.0, dy=0.0):
    """Contornos da tulipa num espaço lógico de 1000x1000.

    Devolve (copa, caule, folha_esquerda, folha_direita), cada um uma lista de
    pontos já escalada e transladada.
    """

    def t(pontos):
        return [((x + dx) * escala, (y + dy) * escala) for x, y in pontos]

    # Copa: três pétalas. Começa na base esquerda, sobe pela pétala esquerda,
    # desce no vão, sobe na pétala central, desce no vão, sobe na direita e
    # fecha pela base arredondada.
    copa = []
    copa += bezier((352, 486), (330, 372), (381, 318))
    copa += bezier((381, 318), (404, 372), (443, 404))
    copa += bezier((443, 404), (458, 330), (500, 292))
    copa += bezier((500, 292), (542, 330), (557, 404))
    copa += bezier((557, 404), (596, 372), (619, 318))
    copa += bezier((619, 318), (670, 372), (648, 486))
    copa += bezier((648, 486), (640, 574), (500, 586))
    copa += bezier((500, 586), (360, 574), (352, 486))

    # Caule: faixa fina com leve curva à esquerda.
    caule_esq = bezier((486, 566), (474, 690), (486, 836))
    caule_dir = list(reversed(bezier((514, 566), (526, 690), (514, 836))))
    caule = caule_esq + caule_dir

    # Folhas: uma de cada lado, saindo do caule.
    folha_esq = bezier((492, 700), (380, 690), (330, 772))
    folha_esq += bezier((330, 772), (420, 800), (492, 744))

    folha_dir = bezier((508, 676), (620, 666), (670, 748))
    folha_dir += bezier((670, 748), (580, 776), (508, 720))

    return t(copa), t(caule), t(folha_esq), t(folha_dir)


def desenhar(lado, fundo, cor_flor, cor_folha, margem=0.0):
    """Desenha a tulipa num quadrado de `lado` px."""
    grande = lado * SUPER
    img = Image.new("RGBA", (grande, grande), fundo)
    d = ImageDraw.Draw(img)

    # margem: fração do lado que fica livre em volta (ícone adaptativo precisa)
    util = (1.0 - 2 * margem) * ZOOM
    escala = grande / 1000.0 * util
    # recentra depois do zoom, e sobe um pouco
    sobra = (1000.0 - 1000.0 * ZOOM) / 2
    deslocamento_x = margem * 1000.0 + sobra
    deslocamento_y = margem * 1000.0 + sobra - SUBIR

    copa, caule, folha_esq, folha_dir = tulipa(
        escala, dx=deslocamento_x / ZOOM, dy=deslocamento_y / ZOOM
    )

    d.polygon(folha_esq, fill=cor_folha)
    d.polygon(folha_dir, fill=cor_folha)
    d.polygon(caule, fill=cor_folha)
    d.polygon(copa, fill=cor_flor)

    return img.resize((lado, lado), Image.LANCZOS)


def salvar(img, caminho):
    img.save(caminho, "PNG")
    print(f"  {caminho}  {img.size[0]}x{img.size[1]}")


def main():
    print("Gerando ícones do Isa a Bela:")

    # Ícone principal: tulipa branca sobre rosa profundo.
    salvar(desenhar(LADO, ROSA_FUNDO, BRANCO, FOLHA), "assets/images/icon.png")

    # Favicon: mesmo desenho, pequeno.
    salvar(desenhar(48, ROSA_FUNDO, BRANCO, FOLHA), "assets/images/favicon.png")

    # Splash: tulipa rosa sobre fundo transparente, para assentar no fundo claro.
    splash = desenhar(512, (0, 0, 0, 0), ROSA_FUNDO, (235, 122, 156, 255))
    salvar(splash, "assets/images/splash-icon.png")

    # Android adaptativo: o sistema recorta um círculo, então a arte precisa de
    # margem folgada para não perder as pétalas.
    salvar(
        desenhar(512, (0, 0, 0, 0), BRANCO, FOLHA, margem=0.18),
        "assets/images/android-icon-foreground.png",
    )
    salvar(
        Image.new("RGBA", (512, 512), ROSA_FUNDO),
        "assets/images/android-icon-background.png",
    )
    # Monocromático: silhueta branca, usada pelo tema dinâmico do Android.
    salvar(
        desenhar(432, (0, 0, 0, 0), BRANCO, BRANCO, margem=0.18),
        "assets/images/android-icon-monochrome.png",
    )

    print("Pronto. Cores vindas de src/theme/tokens.ts (accent #C2456E).")


if __name__ == "__main__":
    main()
