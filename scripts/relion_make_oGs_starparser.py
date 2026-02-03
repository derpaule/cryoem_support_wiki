#!/usr/bin/env python3

import sys
import os
import re
# Add the starparser package to the path
sys.path.insert(0, '/nethome/timschu/software/anaconda3/envs/starparser')
from starparser import fileparser
import pandas as pd

def extract_gridsquare_and_afis(micrograph_name):
    """
    Extract GridSquare and AFIS group from micrograph name.
    
    GridSquare pattern: GridSquare_XXXXXXX
    AFIS pattern: Data_......._*_........_......_fractions (number marked by *)
    
    Returns tuple: (gridsquare, afis_group)
    """
    gridsquare = None
    afis_group = None
    
    # Extract GridSquare (pattern: GridSquare_XXXXXXX)
    gridsquare_match = re.search(r'GridSquare_(\w+)', micrograph_name)
    if gridsquare_match:
        gridsquare = gridsquare_match.group(1)
    
    # Extract AFIS group (pattern: Data_......._*_........_......_fractions)
    afis_match = re.search(r'Data_[^_]+_(\d+)_[^_]+_[^_]+_fractions', micrograph_name)
    if afis_match:
        afis_group = int(afis_match.group(1))
    
    return gridsquare, afis_group

def main():
    # Check if input file is provided
    if len(sys.argv) != 2:
        print("Usage: python script.py input.star")
        print("Before Usage: conda activate starparser")
        print("Before usage: which starparser")
        print("Before usage: replace the starparser package path with your path")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    # Check if file exists
    if not os.path.exists(input_file):
        print(f"Error: File {input_file} does not exist.")
        sys.exit(1)
    
    # Read the star file using starparser
    try:
        movies_df, metadata = fileparser.getparticles(input_file)
    except Exception as e:
        print(f"Error reading star file: {e}")
        sys.exit(1)
    
    # Extract optics data from metadata
    # metadata format: [version, opticsheaders, alloptics, particlesheaders, tablename]
    version, opticsheaders, optics_df, particlesheaders, tablename = metadata
    
    # Check if we have the correct column name
    if '_rlnMicrographMovieName' in movies_df.columns:
        micrograph_column = '_rlnMicrographMovieName'
    elif '_rlnMicrographName' in movies_df.columns:
        micrograph_column = '_rlnMicrographName'
    else:
        print("Error: Could not find micrograph name column")
        sys.exit(1)
    
    # Extract GridSquare and AFIS information for each movie
    gridsquare_afis_combinations = []
    
    for idx, row in movies_df.iterrows():
        micrograph_name = row[micrograph_column]
        gridsquare, afis_group = extract_gridsquare_and_afis(micrograph_name)
        
        if gridsquare is not None and afis_group is not None:
            gridsquare_afis_combinations.append((gridsquare, afis_group))
        else:
            print(f"Warning: Could not extract GridSquare/AFIS from {micrograph_name}")
            gridsquare_afis_combinations.append((None, None))
    
    # Create unique combinations and assign optics group numbers
    unique_combinations = list(set([combo for combo in gridsquare_afis_combinations if combo != (None, None)]))
    unique_combinations.sort()  # Sort for consistent ordering
    
    print(f"Found {len(unique_combinations)} unique GridSquare/AFIS combinations:")
    for i, (gs, afis) in enumerate(unique_combinations, 1):
        print(f"  OpticsGroup {i}: GridSquare_{gs}, AFIS_{afis}")
    
    # Create mapping from combination to optics group number
    combo_to_optics = {combo: i for i, combo in enumerate(unique_combinations, 1)}
    
    # Assign optics group numbers to movies
    optics_groups = []
    for combo in gridsquare_afis_combinations:
        if combo in combo_to_optics:
            optics_groups.append(combo_to_optics[combo])
        else:
            optics_groups.append(1)  # Default to group 1 if extraction failed
    
    movies_df['_rlnOpticsGroup'] = optics_groups
    
    # Create new optics table with one entry per unique combination
    new_optics_data = []
    for i, (gridsquare, afis_group) in enumerate(unique_combinations, 1):
        # Use the first optics entry as template and modify
        if len(optics_df) > 0:
            optics_row = optics_df.iloc[0].copy()
        else:
            # Create a basic optics row if none exists
            optics_row = pd.Series()
            for header in opticsheaders:
                if header == '_rlnOpticsGroup':
                    optics_row[header] = i
                elif header == '_rlnOpticsGroupName':
                    optics_row[header] = f"opticsGroup{i}"
                else:
                    optics_row[header] = "1.000000"  # Default value
        
        optics_row['_rlnOpticsGroup'] = i
        optics_row['_rlnOpticsGroupName'] = f"opticsGroup{i}"
        new_optics_data.append(optics_row)
    
    new_optics_df = pd.DataFrame(new_optics_data)
    
    # Update metadata with new optics information
    new_metadata = [version, opticsheaders, new_optics_df, particlesheaders, tablename]
    
    # Generate output filename
    base_name = os.path.splitext(input_file)[0]
    output_file = f"{base_name}_optics_groups.star"
    
    # Write the output star file using starparser
    try:
        fileparser.writestar(movies_df, new_metadata, output_file)
        print(f"\nOutput written to: {output_file}")
        print(f"Created {len(unique_combinations)} optics groups")
    except Exception as e:
        print(f"Error writing output file: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
