#!/usr/bin/env python3
"""
Generate FaithConnect app icon - A beautiful faith-themed logo
Features: Praying hands with a connecting arc/circle representing community
"""

try:
    from PIL import Image, ImageDraw, ImageFont
    import math
except ImportError:
    print("Installing required package: Pillow")
    import subprocess
    import sys
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageDraw, ImageFont
    import math

def create_faith_icon():
    """Create a faith-themed app icon with praying hands and community circle"""
    
    # Icon size (1024x1024 for high quality)
    size = 1024
    
    # Create image with gradient background
    img = Image.new('RGB', (size, size), '#6366F1')
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (indigo to purple)
    for y in range(size):
        # Gradient from #6366F1 (indigo) to #8B5CF6 (purple)
        r = int(99 + (139 - 99) * y / size)
        g = int(102 + (92 - 102) * y / size)
        b = int(241 + (246 - 241) * y / size)
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b))
    
    # Center point
    cx, cy = size // 2, size // 2
    
    # Draw large "F" and "C" letters stylized as a logo
    # Letter F
    f_left = cx - int(size * 0.22)
    f_top = cy - int(size * 0.25)
    f_width = int(size * 0.15)
    f_height = int(size * 0.5)
    thickness = int(size * 0.06)
    
    # F vertical bar
    draw.rectangle(
        [(f_left, f_top), (f_left + thickness, f_top + f_height)],
        fill=(255, 255, 255, 255)
    )
    # F top horizontal
    draw.rectangle(
        [(f_left, f_top), (f_left + f_width, f_top + thickness)],
        fill=(255, 255, 255, 255)
    )
    # F middle horizontal
    draw.rectangle(
        [(f_left, f_top + f_height // 3), (f_left + f_width * 0.8, f_top + f_height // 3 + thickness)],
        fill=(255, 255, 255, 255)
    )
    
    # Letter C
    c_right = cx + int(size * 0.22)
    c_top = cy - int(size * 0.25)
    c_width = int(size * 0.18)
    c_height = int(size * 0.5)
    c_thickness = int(size * 0.06)
    
    # Draw C as an arc (circle with opening on right)
    c_radius = c_height // 2
    c_cx = c_right - c_radius
    c_cy = c_top + c_radius
    
    # Outer circle
    draw.ellipse(
        [(c_cx - c_radius, c_cy - c_radius), 
         (c_cx + c_radius, c_cy + c_radius)],
        outline=(255, 255, 255, 255),
        width=c_thickness
    )
    
    # Cover right side to create C opening
    cover_width = int(size * 0.1)
    draw.rectangle(
        [(c_cx + c_radius - c_thickness, c_cy - cover_width),
         (c_cx + c_radius + c_thickness, c_cy + cover_width)],
        fill=(int(99 + (139 - 99) * 0.5), int(102 + (92 - 102) * 0.5), int(241 + (246 - 241) * 0.5))
    )
    
    # Add decorative elements
    # Circle around the logo
    circle_radius = int(size * 0.42)
    draw.ellipse(
        [(cx - circle_radius, cy - circle_radius), 
         (cx + circle_radius, cy + circle_radius)],
        outline=(255, 255, 255, 100),
        width=int(size * 0.008)
    )
    
    # Add three dots at top (representing multiple faiths)
    dot_radius = int(size * 0.025)
    dot_y = cy - int(size * 0.38)
    for i in range(-1, 2):
        dot_x = cx + i * int(size * 0.1)
        draw.ellipse(
            [(dot_x - dot_radius, dot_y - dot_radius),
             (dot_x + dot_radius, dot_y + dot_radius)],
            fill=(255, 255, 255, 255)
        )
    
    # Add connecting arc at bottom (community)
    arc_y = cy + int(size * 0.35)
    arc_radius = int(size * 0.25)
    draw.arc(
        [(cx - arc_radius, arc_y - arc_radius),
         (cx + arc_radius, arc_y + arc_radius)],
        start=0, end=180,
        fill=(255, 255, 255, 255),
        width=int(size * 0.015)
    )
    
    return img

def create_foreground_icon():
    """Create foreground icon for adaptive Android icon"""
    size = 1024
    
    # Transparent background
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    
    # Draw large "F" and "C" letters
    # Letter F
    f_left = cx - int(size * 0.18)
    f_top = cy - int(size * 0.2)
    f_width = int(size * 0.12)
    f_height = int(size * 0.4)
    thickness = int(size * 0.05)
    
    # F vertical bar
    draw.rectangle(
        [(f_left, f_top), (f_left + thickness, f_top + f_height)],
        fill=(255, 255, 255, 255)
    )
    # F top horizontal
    draw.rectangle(
        [(f_left, f_top), (f_left + f_width, f_top + thickness)],
        fill=(255, 255, 255, 255)
    )
    # F middle horizontal
    draw.rectangle(
        [(f_left, f_top + f_height // 3), (f_left + int(f_width * 0.8), f_top + f_height // 3 + thickness)],
        fill=(255, 255, 255, 255)
    )
    
    # Letter C
    c_right = cx + int(size * 0.18)
    c_top = cy - int(size * 0.2)
    c_height = int(size * 0.4)
    c_thickness = int(size * 0.05)
    
    # Draw C as an arc
    c_radius = c_height // 2
    c_cx = c_right - c_radius
    c_cy = c_top + c_radius
    
    # Outer circle
    draw.ellipse(
        [(c_cx - c_radius, c_cy - c_radius), 
         (c_cx + c_radius, c_cy + c_radius)],
        outline=(255, 255, 255, 255),
        width=c_thickness
    )
    
    # Cover right side to create C opening
    cover_width = int(size * 0.08)
    draw.rectangle(
        [(c_cx + c_radius - c_thickness, c_cy - cover_width),
         (c_cx + c_radius + c_thickness, c_cy + cover_width)],
        fill=(0, 0, 0, 0)
    )
    
    # Three dots at top
    dot_radius = int(size * 0.02)
    dot_y = cy - int(size * 0.32)
    for i in range(-1, 2):
        dot_x = cx + i * int(size * 0.08)
        draw.ellipse(
            [(dot_x - dot_radius, dot_y - dot_radius),
             (dot_x + dot_radius, dot_y + dot_radius)],
            fill=(255, 255, 255, 255)
        )
    
    return img

if __name__ == "__main__":
    print("🎨 Generating FaithConnect app icons...")
    
    # Create main icon
    print("  Creating main app icon (1024x1024)...")
    icon = create_faith_icon()
    icon.save('assets/app_icon.png', 'PNG')
    print("  ✓ Saved: assets/app_icon.png")
    
    # Create foreground for adaptive icon
    print("  Creating adaptive icon foreground...")
    foreground = create_foreground_icon()
    foreground.save('assets/app_icon_foreground.png', 'PNG')
    print("  ✓ Saved: assets/app_icon_foreground.png")
    
    print("\n✨ Icons generated successfully!")
    print("\n📱 Next steps:")
    print("  1. Run: flutter pub get")
    print("  2. Run: flutter pub run flutter_launcher_icons")
    print("  3. Run your app to see the new icon!")
