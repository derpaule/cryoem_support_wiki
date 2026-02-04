#!/bin/bash

# Usage: ./process_rotations.sh --i <input_folder> --o <output_folder>
# Example: ./process_rotations.sh --i Refine3D/job375 --o Project_analysis/job375
# requires RELION and Eman2

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --i) input_folder="$2"; shift ;;
        --o) output_folder="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check if input and output folders are provided
if [[ -z "$input_folder" || -z "$output_folder" ]]; then
    echo "Both --i (input folder) and --o (output folder) must be specified."
    exit 1
fi

# Ensure the output folder exists
mkdir -p "$output_folder"

# Loop through rotation angles from 0 to 180 in 5 degree steps
for rot in $(seq 0 5 360); do
    # Format rotation angle with leading zeroes (e.g., 00, 05, 10, etc.)
    rot_formatted=$(printf "%02d" $rot)

    # Define input and output filenames
    input_file="$input_folder/run_class001.mrc"
    output_mrcs="$output_folder/rot_${rot_formatted}.mrcs"
    output_png="$output_folder/rot_${rot_formatted}.png"

    # Run relion_project command
    echo "Running: relion_project --i $input_file --o $output_mrcs --tilt 90 --rot $rot"
    relion_project --i "$input_file" --o "$output_mrcs" --tilt 90 --rot $rot

    # Run e2proc2d.py command
    echo "Running: e2proc2d.py $output_mrcs $output_png"
    e2proc2d.py "$output_mrcs" "$output_png"
done

echo "Processing completed!"
