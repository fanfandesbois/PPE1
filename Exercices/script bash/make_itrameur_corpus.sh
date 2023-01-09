#!/usr/bin/env bash

#=======================================================================
# script pour créer le corpus itrameur
# doit être exécuté depuis la racine du projet
# cela lui permet de récupérer les fichiers dans les bons dossiers
#
# Se lancera donc comme ça : ./scripts/make_itrameur_corpus.sh <dossier>
#=======================================================================

if [[ $# -ne 1 ]]
then
	echo "Un argument attendu: <dossier>"
	exit
fi


folder=$1 # dumps-text/ OU contextes/ (attention, ne pas oublier le "/" après le nom du répertoire)
if [ $folder == "dumps-text/" ]
then
	foldername="dumps"
elif [ $folder == "contextes/" ]
then
	foldername="contextes"
fi
path="$folder*"
#echo "$path"

# création du fichier de concaténation
concatenationFile="./iTrameur/$foldername.txt"
touch $concatenationFile

for subpath in $path
do
	basename=$(echo "$subpath" | egrep -o "(fr)|(jp)|(kr)|(pt)")
	
	output="./iTrameur/$foldername-$basename.txt"
	
	echo "<lang=\"$basename\">" > $output
	
	for filepath in $subpath/*
	do
		# filepath == dumps-texts/jp-1.txt
		# 	==> pagename = fr-1
		if [[ $filepath =~ .*jp.*[^(tok)].txt ]]
		then
			continue
		fi
		#echo "$filepath"
		filename=$(echo "$file" | basename -s .txt $filepath)
		echo "<page=\"$filename\">" >> $output
		echo "<text>" >> $output
		
		#on récupère les dumps/contextes
		#et on écrit à l'intérieur de la balise text
		content=$(cat $filepath) 
		
		# ordre important : & en premier
		# sinon : < => &lt; => &amp;lt;
		content=$(echo "$content" | sed 's/&/&amp/g')
		content=$(echo "$content" | sed 's/</&lt/g')
		content=$(echo "$content" | sed 's/>/&gt/g')
		
		echo "$content" >> $output
		
		echo "</text>" >> $output
		echo "</page> §" >> $output
	done
	echo "</lang>" >> $output
	
	cat "$output" >> $concatenationFile
done

