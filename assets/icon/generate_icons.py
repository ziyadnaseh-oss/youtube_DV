import os
from PIL import Image, ImageDraw

def create_icons():
    size = 1024
    out_dir = r"D:\youtube2\assets\icon"
    os.makedirs(out_dir, exist_ok=True)

    # 1. Create app_icon_foreground.png (transparent background, white symbol in safe zone)
    fg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_fg = ImageDraw.Draw(fg)

    # Download symbol centered at (512, 512)
    # Safe zone is roughly r=330 px (diameter 660 px)
    # Arrow shaft:
    shaft_w = 90
    shaft_left = 512 - shaft_w // 2
    shaft_right = 512 + shaft_w // 2
    shaft_top = 280
    shaft_bottom = 540
    draw_fg.rounded_rectangle([shaft_left, shaft_top, shaft_right, shaft_bottom], radius=20, fill=(255, 255, 255, 255))

    # Arrow head (triangle pointing down):
    # Tip at (512, 670), left corner at (320, 500), right corner at (704, 500)
    arrow_head = [
        (512, 680),   # tip
        (330, 500),   # left
        (400, 500),   # inner left
        (512, 600),   # inner tip
        (624, 500),   # inner right
        (694, 500),   # right
    ]
    # Solid clean triangle:
    draw_fg.polygon([(320, 500), (704, 500), (512, 680)], fill=(255, 255, 255, 255))

    # Tray / base:
    # U-shaped tray: horizontal bar with rounded corners and upturned lips
    tray_thickness = 75
    tray_bottom = 760
    tray_top = tray_bottom - tray_thickness
    tray_left = 300
    tray_right = 724
    lip_height = 80

    # Draw bottom horizontal bar
    draw_fg.rounded_rectangle([tray_left, tray_top, tray_right, tray_bottom], radius=25, fill=(255, 255, 255, 255))
    # Draw left lip
    draw_fg.rounded_rectangle([tray_left, tray_bottom - lip_height, tray_left + tray_thickness, tray_bottom], radius=25, fill=(255, 255, 255, 255))
    # Draw right lip
    draw_fg.rounded_rectangle([tray_right - tray_thickness, tray_bottom - lip_height, tray_right, tray_bottom], radius=25, fill=(255, 255, 255, 255))

    fg_path = os.path.join(out_dir, "app_icon_foreground.png")
    fg.save(fg_path, "PNG")
    print(f"Saved {fg_path}")

    # 2. Create app_icon.png (Full icon with YouTube Red #FF0000 background)
    full_icon = Image.new("RGBA", (size, size), (255, 0, 0, 255))
    # Composite the white foreground symbol over the red background
    full_icon.alpha_composite(fg)

    icon_path = os.path.join(out_dir, "app_icon.png")
    full_icon.save(icon_path, "PNG")
    print(f"Saved {icon_path}")

if __name__ == "__main__":
    create_icons()
