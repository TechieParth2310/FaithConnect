#!/usr/bin/env python3
"""
Generate FaithConnect NEW Premium Logo
Design: "Interconnected Faith" - Multiple faith symbols connected in harmony
Features: Premium gradients, modern design, spiritual unity
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

def create_premium_logo():
    """Create a premium faith-themed logo with interconnected symbols"""
    
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    
    # Premium gradient background (soft purple gradient)
    for y in range(size):
        # Gradient from #F5F3FF (very light purple) at top to #EDE9FE at bottom
        r = int(245 - (245 - 237) * y / size)
        g = int(243 - (243 - 233) * y / size)
        b = int(255 - (255 - 254) * y / size)
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b, 255))
    
    # Draw outer glow circle
    outer_radius = int(size * 0.45)
    for i in range(3):
        alpha = 20 - i * 5
        radius = outer_radius + i * 10
        draw.ellipse(
            [(cx - radius, cy - radius), (cx + radius, cy + radius)],
            outline=(157, 139, 245, alpha),
            width=2
        )
    
    # Main circle with gradient effect (dark purple)
    main_radius = int(size * 0.35)
    for i in range(main_radius, 0, -2):
        # Radial gradient from center
        ratio = i / main_radius
        r = int(157 - (157 - 123) * (1 - ratio))
        g = int(139 - (139 - 111) * (1 - ratio))
        b = int(245 - (245 - 232) * (1 - ratio))
        draw.ellipse(
            [(cx - i, cy - i), (cx + i, cy + i)],
            outline=(r, g, b, 200),
            width=3
        )
    # Fill center
    draw.ellipse(
        [(cx - main_radius, cy - main_radius), (cx + main_radius, cy + main_radius)],
        fill=(157, 139, 245, 180)
    )
    
    # Inner circle (lighter)
    inner_radius = int(size * 0.25)
    draw.ellipse(
        [(cx - inner_radius, cy - inner_radius), (cx + inner_radius, cy + inner_radius)],
        fill=(255, 255, 255, 40),
        outline=(255, 255, 255, 100),
        width=3
    )
    
    # Central infinity symbol (connection/unity)
    infinity_size = int(size * 0.15)
    infinity_thickness = int(size * 0.025)
    
    # Left loop of infinity
    left_cx = cx - infinity_size // 2
    draw.ellipse(
        [(left_cx - infinity_size // 2, cy - infinity_size // 2),
         (left_cx + infinity_size // 2, cy + infinity_size // 2)],
        outline=(255, 215, 0, 255),  # Gold
        width=infinity_thickness
    )
    
    # Right loop of infinity
    right_cx = cx + infinity_size // 2
    draw.ellipse(
        [(right_cx - infinity_size // 2, cy - infinity_size // 2),
         (right_cx + infinity_size // 2, cy + infinity_size // 2)],
        outline=(255, 215, 0, 255),  # Gold
        width=infinity_thickness
    )
    
    # Connect the loops (infinity middle)
    draw.rectangle(
        [(left_cx + infinity_size // 2 - infinity_thickness // 2, cy - infinity_thickness // 2),
         (right_cx - infinity_size // 2 + infinity_thickness // 2, cy + infinity_thickness // 2)],
        fill=(255, 215, 0, 255)
    )
    
    # Faith symbols around the circle (simplified, abstract)
    symbol_distance = int(size * 0.28)
    symbol_size = int(size * 0.08)
    
    # Top symbol (Om/Circle)
    top_y = cy - symbol_distance
    draw.ellipse(
        [(cx - symbol_size // 2, top_y - symbol_size // 2),
         (cx + symbol_size // 2, top_y + symbol_size // 2)],
        outline=(255, 215, 0, 200),
        width=int(size * 0.015)
    )
    draw.ellipse(
        [(cx - symbol_size // 4, top_y - symbol_size // 4),
         (cx + symbol_size // 4, top_y + symbol_size // 4)],
        fill=(255, 215, 0, 150)
    )
    
    # Right symbol (Crescent)
    right_x = cx + symbol_distance
    draw.arc(
        [(right_x - symbol_size, cy - symbol_size // 2),
         (right_x + symbol_size, cy + symbol_size // 2)],
        start=45,
        end=225,
        fill=(255, 215, 0, 200),
        width=int(size * 0.015)
    )
    
    # Bottom symbol (Cross - simplified)
    bottom_y = cy + symbol_distance
    cross_thickness = int(size * 0.015)
    cross_length = symbol_size
    # Vertical
    draw.rectangle(
        [(cx - cross_thickness // 2, bottom_y - cross_length // 2),
         (cx + cross_thickness // 2, bottom_y + cross_length // 2)],
        fill=(255, 215, 0, 200)
    )
    # Horizontal
    draw.rectangle(
        [(cx - cross_length // 2, bottom_y - cross_thickness // 2),
         (cx + cross_length // 2, bottom_y + cross_thickness // 2)],
        fill=(255, 215, 0, 200)
    )
    
    # Left symbol (Star - simplified)
    left_x = cx - symbol_distance
    star_points = 6
    star_radius_outer = symbol_size // 2
    star_radius_inner = star_radius_outer // 2
    points = []
    for i in range(star_points * 2):
        angle = math.pi * i / star_points
        if i % 2 == 0:
            radius = star_radius_outer
        else:
            radius = star_radius_inner
        x = left_x + radius * math.cos(angle - math.pi / 2)
        y = cy + radius * math.sin(angle - math.pi / 2)
        points.append((x, y))
    draw.polygon(points, fill=(255, 215, 0, 200), outline=(255, 215, 0, 255))
    
    # Connection lines (curved, subtle)
    line_alpha = 80
    line_width = int(size * 0.008)
    
    # Top to center (curve)
    for i in range(50):
        t = i / 50
        x = cx + (cx - cx) * t + (cx - cx) * math.sin(t * math.pi) * 0.3
        y = top_y + (cy - top_y) * t
        draw.ellipse(
            [(x - line_width, y - line_width), (x + line_width, y + line_width)],
            fill=(255, 215, 0, line_alpha)
        )
    
    # Right to center
    for i in range(50):
        t = i / 50
        x = right_x - (right_x - cx) * t
        y = cy + (cy - cy) * t + (cy - cy) * math.sin(t * math.pi) * 0.3
        draw.ellipse(
            [(x - line_width, y - line_width), (x + line_width, y + line_width)],
            fill=(255, 215, 0, line_alpha)
        )
    
    # Sparkle/energy dots
    sparkle_positions = [
        (cx - int(size * 0.38), cy - int(size * 0.38)),
        (cx + int(size * 0.38), cy - int(size * 0.38)),
        (cx - int(size * 0.38), cy + int(size * 0.38)),
        (cx + int(size * 0.38), cy + int(size * 0.38)),
    ]
    for pos in sparkle_positions:
        sparkle_size = int(size * 0.015)
        draw.ellipse(
            [(pos[0] - sparkle_size, pos[1] - sparkle_size),
             (pos[0] + sparkle_size, pos[1] + sparkle_size)],
            fill=(255, 215, 0, 180)
        )
    
    return img

def create_app_icon():
    """Create app icon version (square with background)"""
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Premium gradient background
    for y in range(size):
        # Gradient from #9D8BF5 to #7B6FE8 (matching app theme)
        r = int(157 - (157 - 123) * y / size)
        g = int(139 - (139 - 111) * y / size)
        b = int(245 - (245 - 232) * y / size)
        draw.rectangle([(0, y), (size, y+1)], fill=(r, g, b, 255))
    
    # Draw the logo on top (scaled down slightly for padding)
    logo = create_premium_logo()
    logo_resized = logo.resize((int(size * 0.85), int(size * 0.85)), Image.Resampling.LANCZOS)
    img.paste(logo_resized, (int(size * 0.075), int(size * 0.075)), logo_resized)
    
    return img

def create_foreground_icon():
    """Create foreground icon for adaptive Android icon (transparent background)"""
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    cx, cy = size // 2, size // 2
    
    # Main circle (purple gradient)
    main_radius = int(size * 0.35)
    for i in range(main_radius, 0, -2):
        ratio = i / main_radius
        r = int(157 - (157 - 123) * (1 - ratio))
        g = int(139 - (139 - 111) * (1 - ratio))
        b = int(245 - (245 - 232) * (1 - ratio))
        draw.ellipse(
            [(cx - i, cy - i), (cx + i, cy + i)],
            outline=(r, g, b, 220),
            width=3
        )
    draw.ellipse(
        [(cx - main_radius, cy - main_radius), (cx + main_radius, cy + main_radius)],
        fill=(157, 139, 245, 200)
    )
    
    # Inner circle
    inner_radius = int(size * 0.25)
    draw.ellipse(
        [(cx - inner_radius, cy - inner_radius), (cx + inner_radius, cy + inner_radius)],
        fill=(255, 255, 255, 50),
        outline=(255, 255, 255, 120),
        width=3
    )
    
    # Central infinity symbol
    infinity_size = int(size * 0.15)
    infinity_thickness = int(size * 0.025)
    
    left_cx = cx - infinity_size // 2
    draw.ellipse(
        [(left_cx - infinity_size // 2, cy - infinity_size // 2),
         (left_cx + infinity_size // 2, cy + infinity_size // 2)],
        outline=(255, 215, 0, 255),
        width=infinity_thickness
    )
    
    right_cx = cx + infinity_size // 2
    draw.ellipse(
        [(right_cx - infinity_size // 2, cy - infinity_size // 2),
         (right_cx + infinity_size // 2, cy + infinity_size // 2)],
        outline=(255, 215, 0, 255),
        width=infinity_thickness
    )
    
    draw.rectangle(
        [(left_cx + infinity_size // 2 - infinity_thickness // 2, cy - infinity_thickness // 2),
         (right_cx - infinity_size // 2 + infinity_thickness // 2, cy + infinity_thickness // 2)],
        fill=(255, 215, 0, 255)
    )
    
    return img

if __name__ == "__main__":
    print("🎨 Generating FaithConnect NEW Premium Logo...")
    print("=" * 50)
    
    # Create main app icon
    print("  Creating main app icon (1024x1024)...")
    icon = create_app_icon()
    icon.save('assets/faithconnect_new_premium_logo.png', 'PNG')
    print("  ✅ Saved: assets/faithconnect_new_premium_logo.png")
    
    # Create foreground for adaptive icon
    print("  Creating adaptive icon foreground...")
    foreground = create_foreground_icon()
    foreground.save('assets/app_icon_foreground.png', 'PNG')
    print("  ✅ Saved: assets/app_icon_foreground.png")
    
    # Create logo only (no background)
    print("  Creating logo only (transparent background)...")
    logo_only = create_premium_logo()
    logo_only.save('assets/brand/faithconnect_logo_new.png', 'PNG')
    print("  ✅ Saved: assets/brand/faithconnect_logo_new.png")
    
    print("\n✨ Logo generated successfully!")
    print("\n🎨 Design Features:")
    print("  • Interconnected faith symbols (Om, Crescent, Cross, Star)")
    print("  • Premium purple gradient (#9D8BF5 → #7B6FE8)")
    print("  • Gold accent color (#FFD700)")
    print("  • Central infinity symbol (unity/connection)")
    print("  • Modern, spiritual, premium aesthetic")
    print("\n📱 Next steps:")
    print("  1. Review the generated logo")
    print("  2. Update pubspec.yaml to use the new logo")
    print("  3. Run: flutter pub run flutter_launcher_icons")
    print("  4. Test on devices!")
