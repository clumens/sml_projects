(* Create, manage, and delete browser cookies.
 *
 * $Id: cookie.sig,v 1.1 2004/01/04 17:53:19 chris Exp $
 *)
signature COOKIE =
sig
   (* Throw this on a very few bad cases. *)
   exception CookieError of string

   (* A cookie is represented by a record.  Note the optional stuff. *)
   type cookie = {name: string, value: string, expiry: Date.date option,
                  domain: string option, path: string option, secure: bool}

   (* Construct the cookie lookup table from the apache_env. *)
   val mk_cookie_env: Env.env -> Env.env

   (* Manage cookies. *)
   val mk_cookie: cookie -> string
   val mk_cookies: cookie list -> string
   val delete_cookie: cookie -> string
end
