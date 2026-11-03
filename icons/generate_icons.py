#!/usr/bin/env python3
"""DNA-strand agent icons.

One intertwining strand per series the agent belongs to; strand length
(vertical span + winding) scales with that series' share of the agent.
Winding is disordered: per-strand random phase, frequency and drift,
seeded by the agent slug so every agent's icon is stable and unique.
The bundle axis is NOT always vertical: each agent's axis is picked
from AXES by its seed (vertical, horizontal, diagonals). Texture is
likewise not fixed: each agent's strands use one texture picked from
TEXTURES by its seed. Series colors are the frozen badge colors.
"""
import hashlib, math, random, sys
from PIL import Image, ImageDraw, ImageFilter

SERIES = {
    "directional": "#2196F3",  # 指向性
    "attention":   "#9C27B0",  # 注意力
    "curbcut":     "#FF9800",  # 路缘坡
    "game":        "#00C853",  # 游戏
    "av":          "#E91E63",  # 影视听
    "trace":       "#00897B",  # 描红
    "none":        "#90A4AE",  # 无系列（中性灰，待定）
}
BG = (10, 14, 26, 255)          # deep blue-black
S = 2048                        # draw size (supersampled)
OUT = 1024                      # final icon size
LW = 64                         # strand width at draw size


def strand_points(rng, weight, cx, cy):
    """Return a list of (x, y) points for one disordered strand,
    running along a vertical axis centered at (cx, cy) in a layer
    larger than the icon; the layer is rotated afterwards."""
    span = (0.36 + 0.56 * weight) * S          # span grows with share
    y0 = cy - span / 2.0
    turns = 1.1 + 1.5 * weight * rng.uniform(0.85, 1.15)
    phase = rng.uniform(0, 2 * math.pi)
    phase2 = rng.uniform(0, 2 * math.pi)
    amp = S * rng.uniform(0.085, 0.125)
    amp2 = S * rng.uniform(0.02, 0.045)
    drift_a = S * rng.uniform(0.01, 0.05)      # slow sideways wander = disorder
    drift_f = rng.uniform(0.5, 1.1)
    drift_p = rng.uniform(0, 2 * math.pi)
    n = 260
    pts = []
    for i in range(n + 1):
        t = i / n
        env = math.sin(math.pi * min(1.0, max(0.0, t))) ** 0.35   # taper at ends
        x = (cx + drift_a * math.sin(2 * math.pi * drift_f * t + drift_p)
             + amp * env * math.sin(2 * math.pi * turns * t + phase)
             + amp2 * env * math.sin(2 * math.pi * (turns * 2.7 + 0.4) * t + phase2))
        y = y0 + span * t
        pts.append((x, y))
    return pts


def _rgb(hexs):
    return tuple(int(hexs[i:i + 2], 16) for i in (1, 3, 5))

def _scale(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)

def _lighten(c, f):
    return tuple(int(v + (255 - v) * f) for v in c)

TEXTURES = ["ribbed", "neon", "rope", "beaded", "grain", "dashed"]

def draw_textured_strand(d, hexcolor, pts, rng, texture="ribbed"):
    """One strand rendered in one of several textures. The texture is
    chosen per agent (slug seed), never hard-coded fleet-wide."""
    base = _rgb(hexcolor)
    edge = _scale(base, 0.66)
    n = len(pts)
    flow_f = rng.uniform(1.6, 2.6)            # brightness waves along length
    flow_p = rng.uniform(0, 2 * math.pi)

    def flow(t):
        return 0.84 + 0.24 * math.sin(2 * math.pi * flow_f * t + flow_p)

    def tangent_normal(i):
        x0, y0 = pts[max(0, i - 2)]
        x1, y1 = pts[min(n - 1, i + 2)]
        dx, dy = x1 - x0, y1 - y0
        ln = math.hypot(dx, dy) or 1.0
        nx, ny = -dy / ln, dx / ln
        if nx * -0.45 + ny * -0.75 < 0:
            nx, ny = -nx, -ny
        return nx, ny

    def body(band=None, core=False):
        for i, (x, y) in enumerate(pts):
            t = i / (n - 1)
            m = flow(t) * (band(t) if band else 1.0)
            r = LW / 2
            d.ellipse([x - r, y - r, x + r, y + r], fill=edge)
            r2 = LW * 0.37
            d.ellipse([x - r2, y - r2, x + r2, y + r2], fill=_scale(base, m))
            if core:
                r3 = LW * 0.16
                d.ellipse([x - r3, y - r3, x + r3, y + r3],
                          fill=_scale(_lighten(base, 0.5), m))

    if texture == "beaded":
        # a chain of distinct beads on a thin dark connector
        d.line(pts, fill=(10, 14, 26, 255), width=int(LW * 0.62), joint="curve")
        step = 8                                # bead pitch along the strand
        for i in range(0, n, step):
            x, y = pts[i]
            t = i / (n - 1)
            r = LW * 0.58
            d.ellipse([x - r, y - r, x + r, y + r], fill=edge)
            r2 = LW * 0.47
            d.ellipse([x - r2, y - r2, x + r2, y + r2], fill=_scale(base, flow(t)))
            nx, ny = tangent_normal(i)
            hx, hy = x + nx * LW * 0.15, y + ny * LW * 0.15
            r3 = LW * 0.15
            d.ellipse([hx - r3, hy - r3, hx + r3, hy + r3], fill=_lighten(base, 0.55))
        return

    # dark separator underlay for the continuous textures
    d.line(pts, fill=(10, 14, 26, 255), width=int(LW * 1.5), joint="curve")

    if texture == "ribbed":
        body(band=lambda t: 0.95 + 0.05 * math.sin(2 * math.pi * 16 * t))
        for i, (x, y) in enumerate(pts):       # highlight spine
            nx, ny = tangent_normal(i)
            hx, hy = x + nx * LW * 0.13, y + ny * LW * 0.13
            r3 = LW * 0.16
            d.ellipse([hx - r3, hy - r3, hx + r3, hy + r3],
                      fill=_scale(_lighten(base, 0.5), flow(i / (n - 1))))
        for k in range(1, 10):                  # node beads
            i = int(k * (n - 1) / 10)
            x, y = pts[i]
            r = LW * 0.56
            d.ellipse([x - r, y - r, x + r, y + r], fill=_scale(base, 0.88))
            r2 = LW * 0.2
            d.ellipse([x - r2, y - r2, x + r2, y + r2], fill=_lighten(base, 0.55))
    elif texture == "neon":
        body(core=False)
        for i, (x, y) in enumerate(pts):       # bright core spine
            r3 = LW * 0.17
            d.ellipse([x - r3, y - r3, x + r3, y + r3],
                      fill=_scale(_lighten(base, 0.62), flow(i / (n - 1))))
    elif texture == "rope":
        body(band=lambda t: 0.82 + 0.26 * math.sin(2 * math.pi * 26 * t))
        for i, (x, y) in enumerate(pts):       # highlight weaves side to side
            t = i / (n - 1)
            nx, ny = tangent_normal(i)
            off = math.sin(2 * math.pi * 5 * t) * LW * 0.17
            hx, hy = x + nx * off, y + ny * off
            r3 = LW * 0.14
            d.ellipse([hx - r3, hy - r3, hx + r3, hy + r3],
                      fill=_scale(_lighten(base, 0.5), flow(t)))
    elif texture == "grain":
        body()
        for _ in range(430):                    # matte speckle inside the tube
            i = rng.randrange(n)
            x, y = pts[i]
            ang = rng.uniform(0, 2 * math.pi)
            rad = (rng.random() ** 0.5) * LW * 0.4
            sx, sy = x + rad * math.cos(ang), y + rad * math.sin(ang)
            r = rng.uniform(1.5, 4.5)
            col = _lighten(base, 0.4) if rng.random() < 0.5 else _scale(base, 0.55)
            d.ellipse([sx - r, sy - r, sx + r, sy + r], fill=col)
    elif texture == "dashed":
        for i, (x, y) in enumerate(pts):
            t = i / (n - 1)
            if (t * 9) % 1 > 0.6:
                continue
            r = LW / 2
            d.ellipse([x - r, y - r, x + r, y + r], fill=edge)
            r2 = LW * 0.37
            d.ellipse([x - r2, y - r2, x + r2, y + r2], fill=_scale(base, flow(t)))
            r3 = LW * 0.17
            d.ellipse([x - r3, y - r3, x + r3, y + r3],
                      fill=_scale(_lighten(base, 0.6), flow(t)))
    else:
        body()


# direction axes (degrees, PIL rotate convention) the fleet picks from;
# the bundle axis varies per agent instead of always running vertically
AXES = [0, 24, 45, 68, 90, 112, 135, 158]

def draw_icon(slug, parts, path, angle=None, texture=None):
    """parts: list of (series_key, weight) in drawing-neutral order.
    angle: bundle-axis rotation in degrees; None = seeded pick from AXES.
    texture: strand texture name; None = seeded pick from TEXTURES."""
    seed = int(hashlib.md5(slug.encode()).hexdigest()[:8], 16)
    rng = random.Random(seed)
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    # rounded-square background
    r = int(S * 0.185)
    d.rounded_rectangle([0, 0, S - 1, S - 1], radius=r, fill=BG)

    L = int(S * 1.45)                      # oversized strand layer
    c = L / 2.0
    strands = []
    for key, w in parts:
        cx = c + rng.uniform(-S * 0.03, S * 0.03)
        strands.append((SERIES[key], strand_points(rng, w, cx, c)))

    layer = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    glow = Image.new("RGBA", (L, L), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    for color, pts in strands:
        gd.line(pts, fill=color + "55", width=LW * 2)
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.02))
    layer = Image.alpha_composite(layer, glow)
    d = ImageDraw.Draw(layer)

    # textured tubes, layered in a slug-seeded order; the crossing
    # curves do the intertwining.
    if texture is None:
        texture = rng.choice(TEXTURES)
    order = list(range(len(strands)))
    rng.shuffle(order)
    for idx in order:
        color, pts = strands[idx]
        draw_textured_strand(d, color, pts, rng, texture)

    if angle is None:
        angle = rng.choice(AXES)
    if angle:
        layer = layer.rotate(angle, resample=Image.BICUBIC)
    off = (L - S) // 2
    layer = layer.crop((off, off, off + S, off + S))
    img = Image.alpha_composite(img, layer)

    img = img.resize((OUT, OUT), Image.LANCZOS)
    img.save(path)
    print("wrote", path)


# sample angles/textures are assigned to showcase the ranges;
# fleet generation picks both from the slug seed instead
SAMPLES = [
    ("london-bus-meet", [("directional", 1.0)], -40, "rope"),
    ("koen-shuugou",    [("curbcut", 1.0), ("directional", 0.6)], 90, "beaded"),
    ("fuyu-game-shuu",  [("game", 1.0), ("directional", 0.7), ("attention", 0.5)], 42, "ribbed"),
    ("trace-kanji",     [("trace", 1.0)], 0, "neon"),
    ("dabiaoge",        [("none", 1.0)], -22, "grain"),
]

if __name__ == "__main__":
    import os, json
    args = sys.argv[1:]
    if args and args[0] == "one":
        # one <slug> <parts> <outpath>; parts = "series:weight,..." or "none"
        slug, spec, out = args[1], args[2], args[3]
        if spec == "none":
            parts = [("none", 1.0)]
        else:
            parts = [(k, float(v)) for k, v in (p.split(":") for p in spec.split(","))]
        draw_icon(slug, parts, out)
    elif args and args[0] == "batch":
        # batch <manifest.json> <outdir>; manifest = {slug: [[series, weight], ...]}
        manifest = json.load(open(args[1], encoding="utf-8"))
        outdir = args[2]
        os.makedirs(outdir, exist_ok=True)
        jobs = [(slug, [tuple(p) for p in parts],
                 os.path.join(outdir, f"{slug}.png"))
                for slug, parts in sorted(manifest.items())]
        from multiprocessing import Pool
        with Pool(6) as pool:
            for i, path in enumerate(pool.starmap(draw_icon, jobs), 1):
                if i % 25 == 0 or i == len(jobs):
                    print(f"batch {i}/{len(jobs)}", flush=True)
        print("batch done:", len(jobs))
    else:
        outdir = args[0] if args else "."
        os.makedirs(outdir, exist_ok=True)
        for slug, parts, ang, tex in SAMPLES:
            draw_icon(slug, parts, os.path.join(outdir, f"icon-{slug}.png"), angle=ang, texture=tex)
