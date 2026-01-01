#!/usr/bin/env python3
"""
Create wallpapers from wings-logo-dark.png
- Portrait: 1200x1920
- Landscape: 1920x1200
"""

from PIL import Image
import os

def create_wallpaper(logo_path, output_path, width, height, background_color=(0, 0, 0)):
    """Create a wallpaper with logo centered on dark background"""
    
    # Open the logo
    logo = Image.open(logo_path)
    
    # Calculate scaling to fit logo while preserving aspect ratio
    logo_ratio = logo.width / logo.height
    canvas_ratio = width / height
    
    if logo_ratio > canvas_ratio:
        # Logo is wider relative to canvas - fit by width
        new_width = int(width * 0.8)  # Use 80% of canvas width for padding
        new_height = int(new_width / logo_ratio)
    else:
        # Logo is taller relative to canvas - fit by height
        new_height = int(height * 0.8)  # Use 80% of canvas height for padding
        new_width = int(new_height * logo_ratio)
    
    # Resize logo maintaining aspect ratio
    logo_resized = logo.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Create canvas with dark background
    if logo.mode == 'RGBA':
        # If logo has transparency, create RGBA canvas
        canvas = Image.new('RGBA', (width, height), background_color + (255,))
        # Calculate position to center the logo
        x = (width - new_width) // 2
        y = (height - new_height) // 2
        # Paste logo with alpha channel
        canvas.paste(logo_resized, (x, y), logo_resized)
        # Convert to RGB for final output
        canvas = canvas.convert('RGB')
    else:
        canvas = Image.new('RGB', (width, height), background_color)
        # Calculate position to center the logo
        x = (width - new_width) // 2
        y = (height - new_height) // 2
        canvas.paste(logo_resized, (x, y))
    
    # Save the wallpaper
    canvas.save(output_path, 'PNG', quality=95)
    print(f"✅ Created: {output_path} ({width}x{height})")

def main():
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    logo_path = os.path.join(project_root, 'images', 'wings-logo-dark.png')
    
    if not os.path.exists(logo_path):
        print(f"❌ Logo not found: {logo_path}")
        return
    
    output_dir = os.path.join(project_root, 'images')
    os.makedirs(output_dir, exist_ok=True)
    
    # Create portrait wallpaper (1200x1920)
    portrait_path = os.path.join(output_dir, 'wallpaper-portrait-1200x1920.png')
    create_wallpaper(logo_path, portrait_path, 1200, 1920)
    
    # Create landscape wallpaper (1920x1200)
    landscape_path = os.path.join(output_dir, 'wallpaper-landscape-1920x1200.png')
    create_wallpaper(logo_path, landscape_path, 1920, 1200)
    
    print("\n✅ Wallpapers created successfully!")

if __name__ == '__main__':
    main()











