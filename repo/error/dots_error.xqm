xquery version "4.0";

module namespace dots_error = "error/dots_error"; 
import module namespace add_doc = "backend/update/add_document";

declare function dots_error:process($data) {
  if(empty($data)) then (
    error(xs:QName('add_doc:empty'), 'No data specified')
  ) else (
    $data
  )
};

declare function dots_error:pathError($value as xs:boolean) {
  if ($value)
  then ()
  else
    error(xs:QName('update_doc_ctt:path'), 'Paths are different')
};