xquery version "4.0";

(:~  
: This module allows updating the content of a document.
: @author École nationale des chartes - Philippe Pons
: @since 2025-16-10
: @version  1.0
:)

(: module namespace update_doc_ctt = "backend/update/update_document_content"; :)

import module namespace functx = 'http://www.functx.com';
import module namespace G = "globals";
import module namespace utils = "resolver/utils";

import module namespace resources = "backend/resources_register_builder";
import module namespace fragments = "backend/fragments_register_builder";

declare namespace dots = "https://github.com/chartes/dots/";
declare namespace dc = "http://purl.org/dc/elements/1.1/";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:  
Essayer de tester:
- voir si doc1 a des identifiants DoTS
- si non, RAS
- si oui
  - regarder si doc2 a des identifiants DoTS (deep-equal?)
  - si oui, on continue l'update
  - si non, on propose un message indiquant que les id DoTS du doc1 seront perdus (et demander validation avant de continuer?)
  
Pour retrouver le document, utiliser son docId.
Mais vérifier le path dans l'import folder pour s'assurer que le chemin est bien le même ?
Question : comment changer la collection PAR DÉFAUT d'un document ?

1. Retrouver le doc1 dans la db ($docId)
2. Regarder s'il y a des id DoTS dans doc2
3. Si oui essayer un deep-equal juste sur les id entre doc1 et doc2
4. Si true, alors on passe à 6 ; si false alors 5
5. Message indiquant que les id DoTS seront perdus et demander validation ?
6. Vérifier que le chemin de doc1 et de doc2 est le même
7. Si oui, on passe à 9, si non on passe à 8
8. Si les chemins sont différents, message pour le signaler. Arrêt ou pas ?
9. deep-equal sur les 2 docs pour voir s'il faut recalculer les fragments ?
10. Si true, alors 11 et 12, si false alors 13 et suivant.
11. On supprime doc1 et on ajoute doc2
12. On met à jour les attributs dc:title du document
13. On supprime les fragments de doc1
14. On calcule les nouveaux fragments de doc2
15. On met à jour les attributs @maxCiteDepth, @citeStructure et le dc:title du document.
:)


(:~ This function allows to retrieve the document with the $docId identifier in the import folder $project_dir_path
: @param $docId             document identifier
: @param $project_dir_path  absolute path to the data import folder
: @return TEI document
:)
declare function local:findDocInFolder($docId as xs:string, $project_dir_path) {
  if (collection($project_dir_path)/tei:TEI[@xml:id = $docId])
  then collection($project_dir_path)/tei:TEI[@xml:id = $docId]
  else 
    let $listDoc := file:list($project_dir_path, true())
    for $docPath in $listDoc
    where ends-with($docPath, $docId)
    return
      doc(concat($project_dir_path, $docPath))
};

(:~  This function allows to find the document $docId in his db
: @param document identifier
: @return TEI document
:)
declare function local:findDocInDb($docId) {
  let $db := normalize-space(db:get($G:dots)//dots:document[@dtsResourceId = $docId]/@dbName)
  return
    utils:getDocument($db, $docId)
};

(:~  This function allows to chech if the document $docId in the db has DoTS identifiers
@param $docId document identifier
@return boolean
:)
declare function local:CheckDotsIdinDocToUpdate($docId) {
  let $doc := local:findDocInDb($docId)
  return
    some $ids in  $doc//node()/@xml:id
    satisfies matches($ids, "r[0-9]+")
};

let $docId := "ENCPOS_1972_18"
let $path := "/home/ppons/Bureau/basex_dots/update_issue/corpus/data/"
let $doc := 
  some $d in file:list($path, true())
  satisfies (functx:substring-after-last($d, "/") = $docId)
  (: let $listDoc := file:list($path, true())
  for $d in $listDoc
  let $docName := 
  where $docName = $docId
  return
    $d :)
return
  (: local:findDoc($docId, $path) :)
  if (local:CheckDotsIdinDocToUpdate($docId))
  then 'toto'
  else 'vador'












