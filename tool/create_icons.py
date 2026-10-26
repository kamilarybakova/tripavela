"""Export the supplied Tripavela artwork to platform icon sizes (Pillow).

Keeps the original artwork and proportions; only resizes and flattens against
white for opaque platform icons. Source is preserved in assets/branding/.
"""
from PIL import Image
from pathlib import Path
import json

root = Path(__file__).resolve().parent.parent
source = Image.open(root / 'assets/branding/tripavela-icon-source.png').convert('RGBA')
assert source.width == source.height, 'App icon source must be square'
canvas = Image.new('RGBA', source.size, 'white')
canvas.alpha_composite(source)
icon = canvas.convert('RGB')

def export(path, pixels, *, maskable=False):
    output = icon.resize((pixels, pixels), Image.Resampling.LANCZOS)
    if maskable:
        # Keep the wing inside the browser's circular mask safe area.
        inset = round(pixels * .06)
        padded = Image.new('RGB', (pixels, pixels), 'white')
        padded.paste(icon.resize((pixels - 2 * inset, pixels - 2 * inset), Image.Resampling.LANCZOS), (inset, inset))
        output = padded
    output.save(root / path)

export('assets/images/app-icon.png', 1024)
folder = root / 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for asset in json.loads((folder / 'Contents.json').read_text())['images']:
    if 'filename' in asset:
        pixels = round(float(asset['size'].split('x')[0]) * float(asset['scale'].replace('x', '')))
        export(folder.relative_to(root) / asset['filename'], pixels)
for density, pixels in [('mdpi', 48), ('hdpi', 72), ('xhdpi', 96), ('xxhdpi', 144), ('xxxhdpi', 192)]:
    export(f'android/app/src/main/res/mipmap-{density}/ic_launcher.png', pixels)
for name, pixels in [('Icon-192.png', 192), ('Icon-512.png', 512), ('Icon-maskable-192.png', 192), ('Icon-maskable-512.png', 512)]:
    export(f'web/icons/{name}', pixels, maskable='maskable' in name)
export('web/favicon.png', 32)
for scale, suffix in [(1, ''), (2, '@2x'), (3, '@3x')]:
    export(f'ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{suffix}.png', 168 * scale)
print('Exported Tripavela app icons, favicon and iOS launch artwork')
