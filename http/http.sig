signature HTTP =
sig
   exception StatusCode of int * string

   type httpStatus = int * string
   type url = {host: string, port: int, path: string}

   val get: url -> string
end
