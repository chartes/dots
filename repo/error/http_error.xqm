xquery version "3.1";


module namespace http_error = "error/http_error"; 

declare 
  %rest:error("err:badIdResource")
  %rest:error-param("description", "{$id}")
function http_error:badIdResource(
  $id
) {
  let $message :=
    if ($id)
    then concat("Error 400: resource ID ", "'", $id, "' not found")
    else "Error 400: no resource ID specified"
  return
    web:error(400, $message)
};


declare 
  %rest:error("err:errorNotFound")
  %rest:error-param("description", "{$id}")
function http_error:errorNotFound(
  $message
) {
  web:error(404, $message)
};

declare
  %rest:error("err:errorNotFound")
  %rest:error-param("description", "{$id}")
function http_error:errorInternalServerError(
  $message
) {
  web:error(500, $message)
};

