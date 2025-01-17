xquery version "4.0";

module namespace dots_error = "error/dots_error"; 


declare function dots_error:process($data) {
  if(empty($data)) then (
    error(xs:QName('local:empty'), 'No data specified')
  ) else (
    $data
  )
};
