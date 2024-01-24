xquery version '3.0' ;

module namespace var = 'https://github.com/chartes/dots/variables';

(:~
: Ce module regroupe les variables DoTS de niveau "Projet"
: @version 1
: @date 2024-01-17
: @author École nationale des chartes - Philippe Pons
:)

(: Identifiant du Projet :)
declare variable $var:idProject := "ENCPOS";

(: Nom de la db BaseX du Projet :)
declare variable $var:dbName := "ENCPOS";

(: Titre du projet :)
declare variable $var:titleProject := "Les positions des thèses de l'Ecole nationale des chartes";

(: 
: Chemin absolu vers le dossier où sont stockées les ressources du Projet 
: @todo: préconiser de déposer les ressources dans "webapp/static" pour pouvoir reconstruire facilement le chemin relatif?
: @todo: garder une seule variable pour les chemins et contraindre sur le nom des fichiers pour les documents utiles à DoTS (metadataMapping.xml, CSV / TSV, etc.)?
: tester avec du http?!!!
:)
declare variable $var:pathResources := "/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/TEI/";

(: Variable pour déclarer le séparateur utilisé pour les documents CSV. Attention: un seul séparateur possible commun à tous les documents CSV :)
declare variable $var:separator := "	";

(: Code langue de la langue principale du corpus pour indexation
: @todo: à conserver? utile?
: @todo: le rendre facultatif
:)
declare variable $var:language := "fr";

(: ~~~~~~~~~~~~~~~~~~~~~~~~~~ 
: Variables encore utilisés mais dont la pertinence est discutable
:)

(: Chemin absolu vers le document metadataMapping.xml (si nécessaire) :)
declare variable $var:metadataMapping := "/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/dots/metadata_mapping.xml";

(: Chemin absolu vers le(s) fichiers CSV / TSV de métadonnées (si nécessaire) :)
declare variable $var:metadataCSV := "
/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/dots/encpos.tsv
/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/dots/titles.csv
";

(: Chemin absolu vers le fichiers CSV pour le cas de collections transverses (si nécessaires) :)
declare variable $var:metadataMultipleCollections := "/home/ppons/Bureau/test_multiple_collections.csv";



