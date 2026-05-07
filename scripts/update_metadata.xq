xquery version '4.0';

(:  
Ce script permet de mettre à jour les métadonnées dans les registres DoTS :
- recharge les métadonnées de collection dans le registre des ressources
- recharge les métadonnées de document dans le registre des ressources
- recharge les métadonnées de fragment dans le registre des fragments.

Seules les métadonnées qui viennent des documents CSV / TSV du dossier metadata/ sont rechargées. Pour les fragments, les métadonnées qui viennent des <citeData/> dans les fichiers TEI ne sont pas modifiées. Cela n'aurait pas de sens puisque ni les documents TEI, ni l'organisation des ressources en collection ne sont modifiés ici.
: @todo ajouter des contrôles pour vérifier que la db, les resourcesId et le projectDirPath existent !
: @remarque ce script doit logiquement être lancé après avoir rechargé le dossier metadata/ du dossier de dépôt.
: @todo /!\ Attention, il faut s'assurer que les ressources sont bien dans le switcher DoTS
:)

import module namespace G = "globals";
import module namespace utils_dots = "utils_dots"; 
import module namespace resources = "backend/resources_register_builder";
import module namespace fragments = "backend/fragments_register_builder";
import module namespace dots_error = "error/dots_error"; 

declare default element namespace "https://github.com/chartes/dots/";

declare variable $dbName external;
declare variable $resourceId external := ();

if (db:exists($dbName))
then
  let $tokenizeResourceId := tokenize($resourceId)
  
  let $idProject := utils_dots:getIdProject($dbName)
  let $resources_register := db:get($dbName, $G:resourcesRegister)//member
  let $fragments_register := db:get($dbName, $G:fragmentsRegister)//member
  
  let $csv-coll := resources:getCSV-map($dbName, "collection")
  let $csv-doc := resources:getCSV-map($dbName, "document")
  let $csv-frag := resources:getCSV-map($dbName, "fragment")
  
  (: let $dotsProjectName := resources:getDotsProjectName($idProject) :)
  
  let $resources := 
    if ($resourceId)
    then 
      for $tokenizeId in $tokenizeResourceId
      return $resources_register/node()[@dtsResourceId = $tokenizeId]
    else $resources_register/node()
  let $fragments :=
    if ($resourceId)
    then
      for $tokenizeId in $tokenizeResourceId
      return $fragments_register/fragment
    else
      $fragments_register/fragment
  return
    (
      for $resource in $resources
      let $resourceId := $resource/@dtsResourceId
      let $children := $resource/@totalChildren
      let $parentIds := $resource/@parentIds
      let $el := $resource/name()
      return
        if ($el = "collection")
        then
          replace node $resource with element {$el} {
            $el/@*,
            resources:getCollectionMetadata($dbName, $resourceId, $csv-coll)
            (: $dotsProjectName :)
            }
        else
          replace node $resource with element {$el} {
            $el/@*,
            resources:getDocumentMetadata($dbName, utils_dots:getDocument($dbName, $resourceId), $resourceId, $csv-doc)
            (: $dotsProjectName :)
          },
      for $fragment in $fragments
      let $meta := fragments:getFragmentMetadata($dbName, $fragment/@ref, $csv-frag)
      where $meta
      let $old_metadata := $fragment/node()[name() = $meta/name()]
      return
        if ($old_metadata)
        then replace node $old_metadata with $meta
        else insert node $meta as last into $fragment
    )
else
  update:output(dots_error:dbError($dbName))








  
  