#!/usr/bin/env python3
"""
Generate FaithConnect app icons with improved spacing (no overlap)
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_icon(size=1024):
    """Create app icon with better spacing"""
    
    # Create image with gradient background
    img = Image.new('RGB', (size, size), color='white')
    draw = ImageDraw.Draw(img)
    
    # Create gradient background (indigo to purple)
    for y in range(size):
        ratio = y / size
        r = int(99 + (139 - 99) * ratio)
        g = int(102 + (92 - 102) * ratio)
        b = int(241 + (246 - 241) * ratio)
        draw.line([(0, y), (size, y)], fill=(r, g, b))
    
    # Calculate dimensions with better spacing
    letter_width = size * 0.35  # Wider letters
    letter_height = size * 0.5
    gap = size * 0.08  # Bigger gap between F and C
    total_width = letter_width * 2 + gap
    start_x = (size - total_width) / 2
    start_y = (size - letter_height) / 2
    
    # White color for letters
    white = (255, 255, 255)
    stroke_width = int(size * 0.08)
    
    # Draw letter F (left side)
    f_x = start_x
    f_y = start_y
    
    # F vertical line
    draw.rectangle([
        f_x, f_y,
        f_x + stroke_width, f_y + letter_height
    ], fill=white)
    
    # F top horizontal
    draw.rectangle([
        f_x, f_y,
        f_x + letter_width, f_y + stroke_width
    ], fill=white)
    
    # F middle horizontal
    draw.rectangle([
        f_x, f_y + letter_height * 0.4,
        f_x + letter_width * 0.7, f_y + letter_height * 0.4 + stroke_width
    ], fill=white)
    
    # Draw letter C (right side)
    c_x = f_x + letter_width + gap
    c_y = start_y
    
    # C outer arc
    padding = stroke_width
    draw.arc([
        c_x, c_y,
        c_x + letter_width, c_y + letter_height
    ], start=45, end=315, fill=white, width=stroke_width)
    
    # Add three dots representing different faiths
    dot_size = int(size * 0.06)
    dot_y = size * 0.82
    dot_spacing = size * 0.15
    dot_center_x = size / 2
    
    for i in [-1, 0, 1]:
        x = dot_center_x + i * dot_spacing
        draw.ellipse([
            x - dot_size, dot_y - dot_size,
            x + dot_size, dot_y + dot_size
        ], fill=white)
    
    return img

def create_foreground_icon(size=1024):
    """Create transparent foreground for adaptive icon"""
    
    # Create transparent image
    img = Image.new('RGBA', (size, size), color=(0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions with better spacing
    letter_width = size * 0.35
    letter_height = size * 0.5
    gap = size * 0.08
    total_width = letter_width * 2 + gap
    start_x = (size - total_width) / 2
    start_y = (size - letter_height) / 2
    
    # White color for letters
    white = (255, 255, 255, 255)
    stroke_width = int(size * 0.08)
    
    # Draw letter F
    f_x = start_x
    f_y = start_y
    
    draw.rectangle([
        f_x, f_y,
        f_x + stroke_width, f_y + letter_height
    ], fill=white)
    
    draw.rectangle([
        f_x, f_y,
        f_x + letter_width, f_y + stroke_width
    ], fill=white)
    
    draw.rectangle([
        f_x, f_y + letter_height * 0.4,
        f_x + letter_width * 0.7, f_y + letter_height * 0.4 + stroke_width
    ], fill=white)
    
    # Draw letter C
    c_x = f_x + letter_width + gap
    c_y = start_y
    
    draw.arc([
        c_x, c_y,
        c_x + letter_width, c_y + letter_height
    ], start=45, end=315, fill=white, width=stroke_width)
    
    # Add three dots
    dot_size = int(size * 0.06)
    dot_y = size * 0.82
    dot_spacing = size * 0.15
    dot_center_x = size / 2
    
    for i in [-1, 0, 1]:
        x = dot_center_x + i * dot_spacing
        draw.ellipse([
            x - dot_size, dot_y - dot_size,
            x + dot_size, dot_y + dot_size
        ], fill=white)
    
    return img

def main():
    # Create assets directory if it doesn't exist
    script_dir = os.path.dirname(os.path.abspath(__file__))
    assets_dir = os.path.join(script_dir, 'faith_connect', 'assets')
    os.makedirs(assets_dir, exist_ok=True)
    
    # Generate main icon
    print("Generating main app icon (with better spacing)...")
    icon = create_icon(1024)
    icon_path = os.path.join(assets_dir, 'app_icon.png')
    icon.save(icon_path, 'PNG', quality=95)
    print(f"✓ Saved main icon: {icon_path}")
    
    # Generate foreground for adaptive icon
    print("Generating adaptive icon foreground...")
    foreground = create_foreground_icon(1024)
    foreground_path = os.path.join(assets_dir, 'app_icon_foreground.png')
    foreground.save(foreground_path, 'PNG', quality=95)
    print(f"✓ Saved foreground icon: {foreground_path}")
    
    print("\n✅ Icons generated successfully with better spacing!")
    print("\nNext steps:")
    print("1. cd faith_connect")
    print("2. flutter pub run flutter_launcher_icons")
    print("3. flutter run")

if __name__ == '__main__':
    main()
