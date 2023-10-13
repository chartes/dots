xquery version "3.1";

(:~ 
: Ce document main permet d'utiliser les librairies de fonctions de project.xqm, et root.xqm de DoTS
: @author École nationale des chartes - Philippe Pons
: @since 2023-06-23
: @version  1.0
:)

import module namespace ccg = "https://github.com/chartes/dots/builder/ccg" at "db_switch_builder.xqm";
import module namespace cc = "https://github.com/chartes/dots/builder/cc" at "resources_register_builder.xqm";
import module namespace docR = "https://github.com/chartes/dots/builder/docR" at "fragments_register_builder.xqm";
import module namespace dbc = "https://github.com/chartes/dots/db/dbc" at "../db/db_creator.xqm";
import module namespace dbd = "https://github.com/chartes/dots/db/dbd" at "../db/dots_registers_delete.xqm";
import module namespace G = "https://github.com/chartes/dots/globals" at "../globals.xqm";
import module namespace valid = "https://github.com/chartes/dots/validation/rng_validator" at "../validation/rng_validator.xqm";

(: 1. Vérifier l'existence de la db dots et la créer le cas échéant :)
(: ccg:create_config() :)

(: 2. Créer la base de données BaseX du projet à partir d'un fichier respectant l'ensemble des prérequis 
: /!\ Attention: les arguments sont à renseigner dans le document /dots/db/db_creator.xqm
:)
(: dbc:dbCreate() :)

(: 3. Créer les registres DoTS dans la db Project :)
(: cc:create_config("mon_theatre", "theatre", "Ma collection de théatre", "") :)
cc:create_config("mon_theatre", "theatre", "Ma collection de théatre", "")
 






