#Copyright (C) 2016  Luis.Yanes@earlham.ac.uk, Vanessa.Bueno@earlham.ac.uk
#This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details. You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>

unset -f module
. /tgac/software/testing/lmod/6.1/x86_64/lmod/lmod/init/profile
ml biopython

#Usage: bash Tree_pipeline.sh -o OUTPUT_DIR -i consensus -n PST -c codon3 -s 80 -l 80 -d SCRIPTS. 

#Run this script in the folder where all the consensus files for the libraries you want to include in the analysis are

SPECIES="PST"
OUTPUT_DIR="sorted"
CODON="codon3"
MIN_SEQ=0
MIN_SAMPLES=0
SCRIPTS_DIR="SCRIPTS"

while [[ $# -gt 1 ]]
do
	key="$1"
	case $key in
		-o|--output)
		OUTPUT_DIR="$2"
		shift
		;;

		-i|--InputDir)
		INPUT_DIR="$2"
		shift
		;;

		-n|--name_SPECIES)
		SPECIES="$2"
		shift
		;;

		-c|--codon)
		CODON="$2"
		shift
		;;

		-s|--MinimumSeqs)
		MIN_SEQ="$2"	#minimum percentage of known bases in a sequence for acceptance 
		shift
		;;
		-l|--MinimumLibraries)
		MIN_SAMPLES="$2" #minimum number of accepted samples percentage
		shift
		;;
		-d|--ScriptsDirectory)
		SCRIPTS_DIR="$2"
		shift
		;;
    	*) echo "Usage: bash Tree_pipeline.sh -o OUTPUT_DIR -i consensus -n PST -c codon3 -s 80 -l 80 -d SCRIPTS. Unkown option: $1 " >&2 ; exit 1

	esac
	shift
done		

if [ -z $OUTPUT_DIR ]; then echo "No output directory given! Using the default ('sorted') output directory..." ; fi
if [ -z $INPUT_DIR ]; then echo "No input directory given! Cannot find the consensus files..." ; exit 1; fi
if [ -z $SPECIES ]; then echo "No name of SPECIES given! Using 'PST' by default..." ; fi 
if [ -z $CODON ]; then echo "No codon specified! choices=codon1, codon2, codon3, codon12, codon123. Using 3rd codon by default..." ; fi 
if [ -z $MIN_SEQ ]; then echo "Threshold (0-100) for missing data in a contig not given! Using 0 by default..." ; fi
if [ -z $MIN_SAMPLES ]; then echo "Threshold (0-100) for missing data across all samples not given! Using 0 by default..." ; fi 
if [ -z $SCRIPTS_DIR ]; then echo "No Scripts directory given. Using 'SCRIPTS' directory by default..."; fi

echo OUTPUT= "${OUTPUT_DIR}"
echo INPUT= "${INPUT_DIR}"
echo NAME OF SPECIES = "${SPECIES}"
echo CODON SELECTED = "${CODON}"
echo THRESHOLD SEQUENCE = "${MIN_SEQ}"
echo THRESHOLD SAMPLES = "${MIN_SAMPLES}"


# Create a directory on the working dir where the script was started from
mkdir $OUTPUT_DIR

source python-2.7.9;
source perl-5.22.1;
# Find all the Isolates fasta files and order them by gene

FILES=$INPUT_DIR/"*.fa"
shopt -s nullglob
for f in $FILES;
do
   python $SCRIPTS_DIR/Phylogenetic_Analysis/sort_fasta.py -f $f > $OUTPUT_DIR/$(basename $f).sorted
done

# With all the files ordered by gene and placed in the sorted folder, filter out which genes are relevant (have enough information)
# codon_from_fasta has multiple filtering parameters, the most relevant are -l (minimum percentage of known bases in a sequence for acceptance) -s (minimum number of accepted samples percentage)
 python $SCRIPTS_DIR/Phylogenetic_Analysis/codon_from_fasta.py -d $OUTPUT_DIR -c $CODON -s $MIN_SEQ -l $MIN_SAMPLES

# Select all the gene filtered sequences
 pattern="./$OUTPUT_DIR/*.filtered"
 files=( $pattern )

# Write the PHYLIP header to the final.phy file
 echo -n ${#files[@]} > $SPECIES\_concatinatelan.phy
 echo -n " " >> $SPECIES\_concatinatelan.phy

 wc -m < ${files[0]} >> $SPECIES\_concatinatelan.phy

# Write all the sequences to the final.phy file to generate a sequential PHYLIP file
 for filename in $OUTPUT_DIR/*.filtered; do echo -n "$(basename $filename | cut -d '_' -f 1) "; cat $filename; echo ""; done >> $SPECIES\_concatinatelan.phy

# The final.phy file is ready to go into RAxML

mv $SPECIES\_concatinatelan.phy $OUTPUT_DIR

echo "Final file is done. "

