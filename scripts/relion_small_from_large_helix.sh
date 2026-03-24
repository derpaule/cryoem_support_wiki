#!/bin/bash
# Using starparser to find the helical tubes from extracted large boxes
echo "activate starparser"
echo "./small_from_large_helix.sh"
echo "particles_large.star and particles_small.star need to be in the same folder"
echo "small_from_large.star is the output file"
sed -n '/data_particles/,$p' particles_large.star > large.star
sed -n '1,/data_particles/ { /data_particles/d; p }' particles_large.star > large_id_optics.star
sed -n '/data_particles/,$p' particles_small.star > small.star
sed -n '1,/data_particles/ { /data_particles/d; p }' particles_small.star > small_id_optics.star
head -50 large_id_optics.star | sed -n '1,/opticsGroup1/ {p }' > large_id_optics_one.star

# small
starparser --i small.star --list_column _rlnMicrographName/_rlnHelicalTubeID --opticsless
sed 's/MotionCorr\/job...\/images\/GridSquare_........\/Data\///g' MicrographName.txt > temp0.txt
sed 's/_fractions.mrc//g' temp0.txt > temp1.txt
paste -d '_' temp1.txt HelicalTubeID.txt > small_id.txt
starparser --i small.star --insert_column _rlnID --f small_id.txt --o small_id.star --opticsless

# large
starparser --i large.star --list_column _rlnMicrographName/_rlnHelicalTubeID --opticsless
sed 's/MotionCorr\/job...\/images\/GridSquare_........\/Data\///g' MicrographName.txt > temp0.txt
sed 's/_fractions.mrc//g' temp0.txt > temp1.txt
paste -d '_' temp1.txt HelicalTubeID.txt > large_id.txt
starparser --i large.star --insert_column _rlnID --f large_id.txt --o large_id.star --opticsless
cat large_id.star >> large_id_optics_one.star

# concatenate
starparser --i small_id.star --find_shared _rlnID --f large_id_optics_one.star --opticsless
starparser --i shared.star --o shared_clean.star --remove_column _rlnID --opticsless
sed 's/data_images/data_particles/g' shared_clean.star > shared_clean_particles.star
sed -n '/data_particles/,$p' shared_clean_particles.star > shared_clean_final.star
cat shared_clean_final.star >> small_id_optics.star
# give better name for the output file
mv small_id_optics.star small_from_large.star
echo "the shared particles are found in small_from_large.star with this many particles:"
grep -c "mrcs" small_from_large.star
