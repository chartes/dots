xquery version '3.0' ;

module namespace G = 'https://github.com/chartes/dots/globals';
(:~
: Ce module regroupe les variables globales de DoTS
: @version 1
: @date 2023-07-06 
: @author École nationale des chartes - Philippe Pons
:)

(:~ Variable pour accéder au nom de la base de données dots :)
declare variable $G:dots := "dots";

declare variable $G:dbSwitcher := "dots_db_switcher.xml";

declare variable $G:metadata := "metadata/";

declare variable $G:metadataMapping := "dots_default_metadata_mapping.xml";

(:~ Variable pour accéder au document "resources_register.xml" d'un projet :)
declare variable $G:resourcesRegister := "dots/resources_register.xml";

(:~ Variable pour accéder au document "declaration.xml" d'un projet :)
declare variable $G:declaration := "declaration.xml";

(:~ Variable pour accéder au registre (documentRegister)  qui liste les passages citables:)
declare variable $G:fragmentsRegister := "dots/fragments_register.xml";

(:~ Variable pour accéder au dossier /static :)
declare variable $G:static := concat($G:webapp, "static/");

(:~ Variable pour accéder au webapp :)
declare variable $G:webapp := file:parent(file:base-dir());

(:~ Variable pour accéder au registre (documentRegister)  qui liste les passages citables:)
declare variable $G:xsl := "static/xsl/tei2html.xsl";

declare variable $G:dbSwitchValidation := concat($G:webapp, "dots/schema/dots_db_switcher.rng");

declare variable $G:resourcesValidation := concat($G:webapp, "dots/schema/resources_register.rng");

declare variable $G:fragmentsValidation := concat($G:webapp, "dots/schema/fragments_register.rng");
