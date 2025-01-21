xquery version '4.0' ;

import module namespace script = "script";

declare variable $docId external;
declare variable $project_dir_path external;


if (file:exists($project_dir_path) and contains($project_dir_path, "data/")) then (
  let $variables := map {
    'docId': $docId,
    'project_dir_path': $project_dir_path
  }
  return
    (
      script:execute("update_doc_ctt:handleUpdate", $variables),
      script:execute("update_doc_ctt:updateRegisters", $variables)
    )
) else (
  ""
)