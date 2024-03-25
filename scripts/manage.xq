xquery version "3.1";

(:~ 
: Ce document main permet d'utiliser les librairies de fonctions de project.xqm, et root.xqm de DoTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-06-23
: @version  1.0
:)

import module namespace utils = "https://github.com/chartes/dots/lib" at "../lib/dots_switcher_update.xqm";
(: import module namespace utils = "https://github.com/chartes/dots/api/utils" at "../api/utils.xqm"; :)
(: import module namespace switcher.lib = "https://github.com/chartes/dots/lib" at "../lib/db_switch_builder.xqm"; :)
(: import module namespace cc = "https://github.com/chartes/dots/builder/cc" at "resources_register_builder.xqm";
import module namespace docR = "https://github.com/chartes/dots/builder/docR" at "fragments_register_builder.xqm";
import module namespace multi = "https://github.com/chartes/dots/builder/multi" at "documents_in_multiple_collections.xqm";
import module namespace dbc = "https://github.com/chartes/dots/db/dbc" at "../db/db_creator.xqm";
import module namespace dbd = "https://github.com/chartes/dots/db/dbd" at "../db/dots_registers_delete.xqm";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";


import module namespace utils = "https://github.com/chartes/dots/api/utils" at "../api/utils.xqm"; :)
(: Exemple pour le registre ENDP 
: /!\ Attention, les commandes doivent être lancées successivment.
:)

(: 1. Créer la base de données BaseX du projet à partir d'un fichier respectant l'ensemble des prérequis 
: /!\ Attention: les arguments sont à renseigner dans le document /dots/db/db_creator.xqm :)
(: dbc:dbCreate("ENCPOS", "/home/ppons/Bureau/basex/webapp/dots/data_test/ENCPOS/") :)

(: 2. Vérifier l'existence de la db dots et la créer le cas échéant :)
(: ccg:create_config("idProject", "dbName") :)
(: ccg:create_config("ENCPOS", "ENCPOS") :)

(: 3. Créer les registres DoTS dans la db Project :)
(: cc:create_config("idProjet", "dbName", "Project Title") :)
(: cc:create_config("ducange", "ducange", "Glossarium mediæ et infimæ latinitatis", "") :)
(: cc:create_config("litterature2", "litterature2", "Corpus Test", "") :)
(: cc:create_config("ENCPOS", "ENCPOS", "Les positions des thèses de l'Ecole nationale des chartes") :)

(: 4. Créer des collections transverses :)
(: multi:handle() :)

(: 5. Supprimer  :)
(: dbd:handleDelete() :)
  
  
  
  utils:switcher_update("encpos")
  
  
  
  
  
  
  
  
  