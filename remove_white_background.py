#!/usr/bin/env python3
"""
Remove white background from PNG images and make them transparent
"""
from PIL import Image
import sys

def remove_white_background(input_path, output_path, threshold=240):
    """
    Remove white background from an image

    Args:
        input_path: Path to input image
        output_path: Path to save output image
        threshold: RGB value threshold for considering a pixel as white (0-255)
    """
    # Open the image
    img = Image.open(input_path)

    # Convert to RGBA if not already
    img = img.convert("RGBA")

    # Get pixel data
    pixels = img.load()

    # Get image dimensions
    width, height = img.size

    # Process each pixel
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]

            # If the pixel is close to white, make it transparent
            if r >= threshold and g >= threshold and b >= threshold:
                pixels[x, y] = (r, g, b, 0)  # Set alpha to 0 (transparent)

    # Save the result
    img.save(output_path, "PNG")
    print(f"Saved transparent image to: {output_path}")

if __name__ == "__main__":
    # Process pig image
    pig_input = "/Users/jg_2030/Billix/Billix/Assets.xcassets/pig_loading.imageset/pig_loading.png"
    pig_output = "/Users/jg_2030/Billix/Billix/Assets.xcassets/pig_loading.imageset/pig_loading.png"

    print("Removing white background from pig image...")
    remove_white_background(pig_input, pig_output)

    # Process money stack image
    money_input = "/Users/jg_2030/Billix/Billix/Assets.xcassets/money_stack.imageset/money_stack.png"
    money_output = "/Users/jg_2030/Billix/Billix/Assets.xcassets/money_stack.imageset/money_stack.png"

    print("Removing white background from money stack image...")
    remove_white_background(money_input, money_output)

    print("\nDone! Both images now have transparent backgrounds.")
