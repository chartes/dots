xquery version '4.0' ;

import module namespace script = "script";
import module namespace update_doc_ctt = "backend/update/update_document_content";

declare variable $docId external;
declare variable $project_dir_path external;


update_doc_ctt:handleUpdate($docId, $project_dir_path),
update_doc_ctt:updateRegisters($docId, $project_dir_path)
(: if (file:exists($project_dir_path) and contains($project_dir_path, "data/")) then ( :)
  (: let $variables := map {
    'docId': $docId,
    'project_dir_path': $project_dir_path
  }
  return
    (
      script:execute("update_doc_ctt:handleUpdate", $variables),
      script:execute("update_doc_ctt:updateRegisters", $variables)
    ) :)
 (:) else (
  "toto"
) :)