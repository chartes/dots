xquery version '3.0' ;

module namespace G = 'https://github.com/chartes/dots/globals';
(:~
: Ce module regroupe les variables globales de DoTS
: @version 1
: @date 2023-07-06 
: @author École nationale des chartes - Philippe Pons
:)

(:~ Variable pour accéder au webapp :)
declare variable $G:webapp := file:parent(file:base-dir());

(:~ Variable pour accéder au dossier /static :)
declare variable $G:static := concat($G:webapp, "static/");

(:~ Variable pour accéder au nom de la base de données config :)
declare variable $G:config := "config";

(:~ Variable pour accéder au document "config.xml" d'un projet :)
declare variable $G:configProject := "config.xml";

(:~ Variable pour accéder au document "declaration.xml" d'un projet :)
declare variable $G:declaration := "declaration.xml";

(:~ Variable pour accéder au répertoire "metadata" d'un projet :)
declare variable $G:metadata := "metadata";

(:~ Variable pour accéder au registre (documentRegister)  qui liste les passages citables:)
declare variable $G:register := concat($G:metadata, "/documentRegister");

(:~ Variable pour accéder au registre (documentRegister)  qui liste les passages citables:)
declare variable $G:xsl := "static/xsl/tei2html.xsl";

