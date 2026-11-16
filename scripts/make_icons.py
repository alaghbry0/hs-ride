#!/usr/bin/env python3
"""توليد أيقونات تطبيق HS للنقل البري — شعار HS على تدرج أخضر."""
from PIL import Image, ImageDraw, ImageFont
import os

OUT = "/home/z/my-project/mobile_app/web/icons"
os.makedirs(OUT, exist_ok=True)

# خط عريض للأيقونة — Cairo 700.
FONT_BOLD = "/home/z/my-project/mobile_app/assets/fonts/Cairo-700.ttf"

BRAND = (0, 169, 143)        # #00A98F
BRAND_DARK = (0, 105, 92)    # #00695C


def make_icon(size: int, maskable: bool = False) -> Image.Image:
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    if maskable:
        # ملء كامل مع هامش آمن 20% للـ maskable.
        d.rounded_rectangle([0, 0, size, size], radius=0, fill=BRAND)
    else:
        radius = int(size * 0.22)
        d.rounded_rectangle([0, 0, size, size], radius=radius, fill=BRAND)

    # تدرج بسيط: مستطيل داكن شفاف سفلي.
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    od.rounded_rectangle([0, size // 2, size, size], radius=0, fill=BRAND_DARK + (90,))
    img = Image.alpha_composite(img, overlay)
    d = ImageDraw.Draw(img)

    # نص HS.
    font_size = int(size * 0.42)
    font = ImageFont.truetype(FONT_BOLD, font_size)
    bbox = d.textbbox((0, 0), "HS", font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1]
    d.text((x, y), "HS", font=font, fill=(255, 255, 255, 255))

    # شريط سفلي صغير يوحي بالطريق.
    bar_h = max(2, size // 36)
    d.rounded_rectangle(
        [size * 0.28, size * 0.82, size * 0.72, size * 0.82 + bar_h],
        radius=bar_h / 2,
        fill=(255, 255, 255, 200),
    )
    return img


for sz in (192, 512):
    make_icon(sz).save(f"{OUT}/Icon-{sz}.png")
    make_icon(sz, maskable=True).save(f"{OUT}/Icon-maskable-{sz}.png")

# favicon 64
make_icon(64).save("/home/z/my-project/mobile_app/web/favicon.png")

# أيقونات أندرويد AdaptiveIcon (foreground بسيط).
AI_DIR = "/home/z/my-project/mobile_app/android/app/src/main/res"
fg = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
d = ImageDraw.Draw(fg)
font = ImageFont.truetype(FONT_BOLD, 200)
bbox = d.textbbox((0, 0), "HS", font=font)
d.text(((512 - (bbox[2]-bbox[0]))/2 - bbox[0], (512 - (bbox[3]-bbox[1]))/2 - bbox[1]),
       "HS", font=font, fill=(255, 255, 255, 255))
os.makedirs(f"{AI_DIR}/mipmap-hdpi", exist_ok=True)
fg.resize((162, 162)).save(f"{AI_DIR}/mipmap-hdpi/ic_launcher_foreground.png")

print("icons generated:", os.listdir(OUT))
