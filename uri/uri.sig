signature URI =
sig
   datatype URI = http of {user: string, password: string, host: string,
                           port: int, path: string, query: string, frag: string}
                | unknown of {scheme: string, auth: string, path: string,
                              query: string, frag: string}

   val parse: string -> URI option
end
