(* Manage GET and form parameters.
 *
 * $Id: param.sig,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
signature PARAM =
sig
   (* Build the environment from the apache_env. *)
   val mk_param_env: Env.env -> Env.env
end
