xquery version "3.1";

(:~  
: Ce module permet à un utilisateur de DoTS d'ajouter un ou plusieurs documents au "resources register" d'une db
: @author École nationale des chartes
: @since 2024-10-16
: @version  1.0
:)
(: module namespace dots.add_doc_to_registers = "backend/project_add_document_to_registers"; :)

import module namespace G = "globals";
import module namespace functx = 'http://www.functx.com';

declare default element namespace "https://github.com/chartes/dots/";

declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace dct = "http://purl.org/dc/terms/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

""