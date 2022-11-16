#!/usr/bin/env bash

#===============================================================================
Comportement du programme:
# Script capable de générer les premiers tableaux de données concernant mes URL.
# Comment on lance le programme : 
# Paramètres: 
#===============================================================================

fichier_urls=$1 # le fichier d'URL en entrée
fichier_tableau=$2 # le fichier HTML en sortie

# !!!!!!
# ici on doit vérifier que nos deux paramètres existent, sinon on ferme!
# !!!!!!
# -i => donne des informations sur l'interaction avec le serveur (réponse du serveur) 
# -IL => réponse du serveur + suit les intéractions
# modifier la ligne suivante pour créer effectivement du HTML

echo "Je dois devenir du code HTML à partir de la question 3" > $fichier_tableau

lineno=1;

while read -r line;
do
	echo "ligne $lineno: $line";
	lineno=$((lineno+1));
	n_lines=$(curl -IL $line | head -n 1  )
	#le code de réponse se trouve sur la première ligne 
	head -n ligne_x nom_du_fichier
done < $fichier_urls
