import subprocess
import sys

# Use xcodebuild to clean and rebuild
print("Cleaning build...")
subprocess.run(['xcodebuild', 'clean', '-scheme', 'Billix'], cwd='/Users/jg_2030/Billix')

print("\nPlease manually add these files to your Xcode project:")
print("1. PartProgressRing.swift")
print("2. ProgressPathConnector.swift")
print("\nLocation: Billix/Features/Rewards/Views/Seasons/Components/")
print("\nOr use Xcode: File > Add Files to 'Billix' and add them to the Components group")
