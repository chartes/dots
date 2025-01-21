xquery version "4.0";

module namespace dots_error = "error/dots_error"; 


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