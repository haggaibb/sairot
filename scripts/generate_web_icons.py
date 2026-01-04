#!/usr/bin/env python3
"""
Generate all web icons from wings-logo-1024.png master image

Generates:
- Favicon (128x128, round with circular mask)
- PWA Icons (192x192, 512x512, square)
- Maskable Icons (192x192, 512x512, square, logo at 80%)
- Apple Touch Icon (180x180, square)
- Lowercase variants (icon-192.png, icon-512.png)

Usage:
    python3 scripts/generate_web_icons.py
"""

import os
import sys
from pathlib import Path
from PIL import Image, ImageDraw

# Configuration
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
MASTER_LOGO = PROJECT_ROOT / 'images' / 'wings-logo-1024.png'
WEB_DIR = PROJECT_ROOT / 'web'
ICONS_DIR = WEB_DIR / 'icons'

# Gradient colors (rgb(188,233,245) to white)
GRADIENT_START = (188, 233, 245)
GRADIENT_END = (255, 255, 255)


def create_gradient_background(width, height, start_color, end_color):
    """Create a vertical gradient background from top to bottom."""
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)
    
    for y in range(height):
        # Calculate interpolation factor (0.0 at top, 1.0 at bottom)
        factor = y / (height - 1) if height > 1 else 0
        
        # Interpolate between start and end colors
        r = int(start_color[0] + (end_color[0] - start_color[0]) * factor)
        g = int(start_color[1] + (end_color[1] - start_color[1]) * factor)
        b = int(start_color[2] + (end_color[2] - start_color[2]) * factor)
        
        # Draw horizontal line
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    return image


def create_circular_mask(size):
    """Create a circular mask for the favicon."""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.ellipse([0, 0, size - 1, size - 1], fill=255)
    return mask


def generate_icon(master_logo_path, output_path, size, logo_size=None, apply_circular_mask=False):
    """
    Generate a single icon with gradient background and logo.
    
    Args:
        master_logo_path: Path to master logo image
        output_path: Path to save the generated icon
        size: Output icon size (width and height)
        logo_size: Logo size (width). If None, uses full size
        apply_circular_mask: Whether to apply circular mask (for favicon)
    """
    # Create gradient background
    background = create_gradient_background(size, size, GRADIENT_START, GRADIENT_END)
    
    # Load and resize logo
    logo = Image.open(master_logo_path)
    if logo.mode != 'RGBA':
        logo = logo.convert('RGBA')
    
    # Determine logo size
    if logo_size is None:
        logo_size = size
    
    # Calculate new logo dimensions maintaining aspect ratio
    logo_ratio = logo.width / logo.height
    new_width = logo_size
    new_height = int(new_width / logo_ratio)
    
    # Resize logo
    logo_resized = logo.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Calculate position to center logo
    x_offset = (size - new_width) // 2
    y_offset = (size - new_height) // 2
    
    # Create RGBA version of background for compositing
    if logo_resized.mode == 'RGBA':
        background_rgba = background.convert('RGBA')
        # Paste logo onto background
        background_rgba.paste(logo_resized, (x_offset, y_offset), logo_resized)
        result = background_rgba
    else:
        background.paste(logo_resized, (x_offset, y_offset))
        result = background
    
    # Apply circular mask if requested
    if apply_circular_mask:
        mask = create_circular_mask(size)
        # Apply mask to alpha channel
        if result.mode != 'RGBA':
            result = result.convert('RGBA')
        result.putalpha(mask)
    
    # Ensure output directory exists
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Save icon
    result.save(output_path, 'PNG', optimize=True)
    print(f"✅ Generated: {output_path.relative_to(PROJECT_ROOT)} ({size}x{size})")


def main():
    """Main entry point."""
    print("🎨 Web Icon Generation Script")
    print("=" * 60)
    
    # Check if master logo exists
    if not MASTER_LOGO.exists():
        print(f"❌ Error: Master logo not found: {MASTER_LOGO}")
        print("   Expected path: images/wings-logo-1024.png")
        sys.exit(1)
    
    print(f"📸 Master logo: {MASTER_LOGO.relative_to(PROJECT_ROOT)}")
    print(f"📁 Output directory: {WEB_DIR.relative_to(PROJECT_ROOT)}")
    print()
    
    # Ensure icons directory exists
    ICONS_DIR.mkdir(parents=True, exist_ok=True)
    
    # Generate all icons
    print("Generating web icons...")
    print()
    
    # 1. Favicon (128x128, round with circular mask)
    generate_icon(
        MASTER_LOGO,
        WEB_DIR / 'favicon.png',
        size=128,
        logo_size=128,
        apply_circular_mask=True
    )
    
    # 2. PWA Icons (square, full logo width)
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'Icon-192.png',
        size=192,
        logo_size=192,
        apply_circular_mask=False
    )
    
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'Icon-512.png',
        size=512,
        logo_size=512,
        apply_circular_mask=False
    )
    
    # 3. Maskable Icons (square, logo at 80% for safe zone)
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'Icon-maskable-192.png',
        size=192,
        logo_size=int(192 * 0.8),  # 80% = 153px
        apply_circular_mask=False
    )
    
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'Icon-maskable-512.png',
        size=512,
        logo_size=int(512 * 0.8),  # 80% = 409px
        apply_circular_mask=False
    )
    
    # 4. Apple Touch Icon (180x180, square)
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'apple-touch-icon.png',
        size=180,
        logo_size=180,
        apply_circular_mask=False
    )
    
    # 5. Lowercase variants (same as PWA icons)
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'icon-192.png',
        size=192,
        logo_size=192,
        apply_circular_mask=False
    )
    
    generate_icon(
        MASTER_LOGO,
        ICONS_DIR / 'icon-512.png',
        size=512,
        logo_size=512,
        apply_circular_mask=False
    )
    
    print()
    print("=" * 60)
    print("✅ All web icons generated successfully!")
    print()
    print("Generated icons:")
    print("  - web/favicon.png (128x128, round)")
    print("  - web/icons/Icon-192.png (192x192)")
    print("  - web/icons/Icon-512.png (512x512)")
    print("  - web/icons/Icon-maskable-192.png (192x192, 80% safe zone)")
    print("  - web/icons/Icon-maskable-512.png (512x512, 80% safe zone)")
    print("  - web/icons/apple-touch-icon.png (180x180)")
    print("  - web/icons/icon-192.png (192x192, lowercase)")
    print("  - web/icons/icon-512.png (512x512, lowercase)")


if __name__ == '__main__':
    main()







