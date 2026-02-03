#!/bin/bash
# Using starparser to find the helical tubes from extracted large boxes
echo "activate starparser"
echo "./small_from_large_helix.sh"
echo "particles_large.star and particles_small.star need to be in the same folder"
echo "small_from_large.star is the output file"
sed -n '/data_particles/,$p' particles_large.star > large.star
sed -n '1,/data_particles/ { /data_particles/d; p }' particles_large.star > large_id_optics.star
sed -n '/data_particles/,$p' particles_small.star > small.star

# small
starparser --i small.star --list_column rlnMicrographName/rlnHelicalTubeID --opticsless
sed 's/MotionCorr\/job...\/images\/GridSquare_........\/Data\///g' MicrographName.txt > temp0.txt
sed 's/_fractions.mrc//g' temp0.txt > temp1.txt
paste -d '_' temp1.txt HelicalTubeID.txt > small_id.txt
starparser --i small.star --insert_column ID --f small_id.txt --o small_id.star --opticsless

# large
starparser --i large.star --list_column rlnMicrographName/rlnHelicalTubeID --opticsless
sed 's/MotionCorr\/job...\/images\/GridSquare_........\/Data\///g' MicrographName.txt > temp0.txt
sed 's/_fractions.mrc//g' temp0.txt > temp1.txt
paste -d '_' temp1.txt HelicalTubeID.txt > large_id.txt
starparser --i large.star --insert_column ID --f large_id.txt --o large_id.star --opticsless

# concatenate
starparser --i small_id.star --find_shared rlnID --f large_id.star --opticsless
starparser --i shared.star --o shared_clean.star --remove_column rlnID --opticsless
sed 's/data_images/data_particles/g' shared_clean.star > shared_clean_particles.star
sed -n '/data_particles/,$p' shared_clean_particles.star > shared_clean_final.star
cat shared_clean_final.star >> large_id_optics.star
# give better name for the output file
mv large_id_optics.star small_from_large.star
