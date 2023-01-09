#!/usr/bin/env bash

#=======================================================================
# script pour créer un tableau html et le concordancier
# prend 4 arguments :
#	1: le nom du fichier en entrée contenant les urls 
#	2: le nom du fichier html de tableau renvoyé en sortie  
#   3: le nom du fichier html du concordancier  renvoyé en sortie
#	4: le mot dans la langue considérée
# Pour lancer le script: 
# ./script/base_tableaux_fichier.sh <fichier_url> <fichier_html> <fichier_concordancier> <mot>
#=======================================================================

fichier_urls=$1 # le fichier d'URL en entrée
fichier_tableau=$2 # le fichier HTML en sortie
fichier_concordancier=$3 # le fichier concordancier en sortie
mot=$4 # le mot dans la langue cherchée

if [[ $# -ne 4 ]]
then
	echo "Quatre arguments attendus: <fichier_URL> <fichier_HTML> <fichier_concordancier> <mot>"
	exit
fi


echo $fichier_urls;
basename=$(basename -s .txt $fichier_urls)
lang=$(basename -s .txt $fichier_urls | sed "s/URL_//g")

######

# Initialisation tableau URLs

echo "<html><body>" > $fichier_tableau
echo "<h2>Tableau $basename :</h2>" >> $fichier_tableau
echo "<br/>" >> $fichier_tableau
echo "<table>" >> $fichier_tableau
echo "<tr><th>ligne</th><th>code</th><th>URL</th><th>encodage</th><th>aspiration</th><th>dump-text</th><th>occurrences</th><th>contextes</th></tr>" >> $fichier_tableau


# Initialisation concordancier

echo "<html><body>" > $fichier_concordancier
echo "<h2>Tableau $basename :</h2>" >> $fichier_concordancier
echo "<br/>" >> $fichier_concordancier
echo "<table>" >> $fichier_concordancier
echo "<tr><th>Contexte gauche</th><th class=\"centre-tableau\">$mot</th><th>Contexte droit</th></tr>" >> $fichier_concordancier

######

lineno=1;
while read -r URL; do
	echo -e "\tURL : $URL";
	# la façon attendue, sans l'option -w de cURL
	code=$(curl -ILs $URL | grep -e "^HTTP/" | grep -Eo "[0-9]{3}" | tail -n 1)
	charset=$(curl -ILs $URL | grep -Eo "charset=(\w|-)+" | tail -n 1 | cut -d= -f2)
	#contenu=$(curl $URL) 

	# autre façon, avec l'option -w de cURL
	# code=$(curl -Ls -o /dev/null -w "%{http_code}" $URL)
	# charset=$(curl -ILs -o /dev/null -w "%{content_type}" $URL | grep -Eo "charset=(\w|-)+" | cut -d= -f2)
	
	
	echo -e "\tcode : $code";

	if [[ ! $charset ]]
	then
		echo -e "\tencodage non détecté, on prendra UTF-8 par défaut.";
		charset="UTF-8";
	else
		echo -e "\tencodage : $charset";
	fi

	if [[ $code -eq 200 ]]
	then
		dump=$(lynx -dump -nolist -assume_charset=$charset -display_charset=$charset $URL)
	
		
		if [[ $charset -ne "UTF-8" && -n "$dump" ]]
		then
			dump=$(echo $dump | iconv -f $charset -t UTF-8//IGNORE)
	
		fi
		
		curl $URL > ./aspirations/$lang/$basename-$lineno.html
		echo "$dump" > ./dumps-text/$lang/$basename-$lineno.txt
		contexte=$(echo "$dump" | egrep -i -A 1 -B 1 "$mot")
		echo "$contexte" > ./contextes/$lang/$basename-$lineno.txt
		
		nb_occ=$(echo "$dump" | egrep -io "$mot" | wc -w)
		
		dump_continu=$(echo "$dump" | sed ':a;N;$!ba;s/\n\n/§/g')
		dump_continu=$(echo "$dump_continu" | sed ':a;N;$!ba;s/\n//g')
		dump_continu=$(echo "$dump_continu" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g')
		
		
		contexte_concordance=$(echo "$dump_continu" | egrep -io "[。.?？！!…§][^。.?？！!…§]*$mot[^。.?？！!…§]*[。.?？！!…§]")
		
		while read -r line
		do
			contexte_gauche=$(echo "$line" | sed -s "s/[。.?？！!…§]\([^。.?？！!…§]*\)$mot\([^。.?？！!…§]*[。.?？！!…§]\)/\1/g")
			contexte_droit=$(echo "$line" | sed -s "s/[。.?？！!…§]\([^。.?？！!…§]*\)$mot\([^。.?？！!…§]*[。.?？！!…§]\)/\2/g")
			echo "<tr><td class=\"has-text-right\">$contexte_gauche</td><td class=\"centre-tableau\">$mot</td><td class=\"has-text-left\">$contexte_droit</td></tr>" >> $fichier_concordancier
		done <<< $contexte_concordance
		
	else
		echo -e "\tcode différent de 200 utilisation d'un dump vide"
		dump=""
		charset=""
	fi
	URL=$(echo "$URL" | sed 's/\&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g' )
	# Met l'encodage en majuscule
	charset=$(echo ${charset^^})
	# Remplit le tableau avec les informations récupérés pour l'URL en cours de lecture
	echo "<tr><td>$lineno</td><td>$code</td><td><a href=\"$URL\">$URL</a></td><td>$charset</td><td><a href=\"../aspirations/$lang/$basename-$lineno.html\">aspiration</a></td><td><a href=\"../dumps-text/$lang/$basename-$lineno.txt\">dump</a></td><td>$nb_occ</td><td><a href=\"../contextes/$lang/$basename-$lineno.txt\"> contextes</a></td></tr>" >> $fichier_tableau
	echo -e "\t--------------------------------"
	lineno=$((lineno+1));
done < $fichier_urls

######

# Fermeture fichier tableau URL

echo "</table>" >> $fichier_tableau
echo "</body></html>" >> $fichier_tableau

# Fermeture fichier concordancier

echo "</table>" >> $fichier_concordancier
echo "</body></html>" >> $fichier_concordancier
