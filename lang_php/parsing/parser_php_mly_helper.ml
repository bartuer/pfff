(*s: parser_php_mly_helper.ml *)
open Common

open Ast_php

(*****************************************************************************)
(* Parse helpers functions *)
(*****************************************************************************)
(*s: function top_statements_to_toplevels *)
(* could have also created some fake Blocks, but simpler to have a 
 * dedicated constructor for toplevel statements *)
let rec top_statements_to_toplevels topstatements eofinfo = 
  match topstatements with
  | [] -> [FinalDef eofinfo]
  | x::xs ->
      let v, rest = 
        (match x with
        | FuncDefNested      def -> FuncDef def,  xs
        | ClassDefNested     def -> ClassDef def, xs
        | InterfaceDefNested def -> InterfaceDef def, xs
        | Stmt st -> 
            let stmts, rest = xs +> Common.span (function 
              | Stmt st -> true 
              | _ -> false
              ) in
            let stmts' = stmts +> List.map (function 
              | Stmt st -> st
              | _ -> raise Impossible
            ) in
            StmtList (st::stmts'), rest
        )
      in
      v::top_statements_to_toplevels rest eofinfo
(*e: function top_statements_to_toplevels *)

(*****************************************************************************)
(* Variable original type *)
(*****************************************************************************)
(*s: type variable2 *)
(* This type is only used for now during parsing time. It was originally
 * fully part of the PHP AST but it makes some processing like typing
 * harder with all the special cases. This type is more precise 
 * than the one currently in the AST but it's not worthwhile the
 * extra complexity.
 *)
type variable2 =
  | Variable of base_var_and_funcall * obj_access list

  and base_var_and_funcall = 
    | BaseVar of base_variable
    | FunCall of func_head * argument comma_list paren

    and base_variable = qualifier option * var_without_obj
      and var_without_obj = indirect list * ref_variable

      and ref_variable = 
        | Var2 of dname * Scope_php.phpscope ref  (* semantic: *)
        | VDollar2 of tok * expr brace
        | VArrayAccess2 of ref_variable * expr option bracket
        | VBraceAccess2 of ref_variable * expr brace


    and func_head = 
      (* static function call (or mostly static because in php
       * you can redefine functions ...)  *)
      | FuncName of qualifier option * name
      (* dynamic function call *)
      | FuncVar  of qualifier option * var_without_obj
(*e: type variable2 *)

(*s: variable2 to variable functions *)
let mkvar var = var, noTypeVar()

let method_object_simple x = 
  match x with
  | ObjAccess(var, (t1, obj, argsopt)) ->
      (match obj, argsopt with
      | ObjProp (OName name), Some args ->
          (* todo? do special case when var is a Var ? *)
          MethodCallSimple (var, t1, name, args)
      | ObjProp (OName name), None ->
          ObjAccessSimple (var, t1, name)
      | _ -> x
      )          
  | _ -> 
      raise Impossible

let rec variable2_to_lvalue var = 
  match var with
  | Variable (basevar, objs) -> 
      let v = basevarfun_to_variable basevar in
      (* TODO left ? right ? *)
      objs +> List.fold_left (fun acc obj ->
        mkvar (method_object_simple (ObjAccess (acc, obj)))
      ) v

and basevarfun_to_variable basevarfun = 
  match basevarfun with
  | BaseVar basevar ->
      basevar_to_variable basevar
  | FunCall (head, args) ->
      let v = 
      (match head with
      | FuncName (qopt, name) -> 
          (match qopt with
          | None -> 
              FunCallSimple (name, args)
          | Some qualifier -> 
              StaticMethodCallSimple (qualifier, name, args)
          )
      | FuncVar (qopt, vwithoutobj) ->
          FunCallVar (qopt, vwithoutobj_to_variable vwithoutobj, args)
      )
      in
      mkvar v


and basevar_to_variable basevar =
  let (qu_opt, vwithoutobj) = basevar in
  let v = vwithoutobj_to_variable vwithoutobj in
  (match qu_opt with
  | None -> v
  | Some qu -> mkvar (VQualifier (qu, v))
  )

and vwithoutobj_to_variable vwithoutobj = 
  let (indirects, refvar) = vwithoutobj in
  let v = refvar_to_variable refvar in
  indirects +> List.fold_left (fun acc indirect ->
    mkvar (Indirect (acc, indirect))) v
  

and refvar_to_variable refvar = 
  let v = 
    match refvar with
    | Var2 (name, scope) -> 
        (match name with
        | DName ("this", info) -> 
            This (info)
        | _ -> 
            Var(name, scope)
        )

    | VDollar2 (tok, exprp) -> VBrace(tok, exprp)
    | VArrayAccess2(refvar, exprb) -> 
        let v = refvar_to_variable refvar in
        VArrayAccess(v, exprb)
    | VBraceAccess2(refvar, exprb) ->
        let v = refvar_to_variable refvar in
        VBraceAccess(v, exprb)
  in
  mkvar v

(*e: variable2 to variable functions *)

(*****************************************************************************)
(* XHP *)
(*****************************************************************************)
let failwith_xhp_ambiguity_colon info =
  let err = 
    "XHP: ambiguity on ':', please put a space after the colon in " ^
      Ast_php.string_of_info info
  in
  (*failwith err*)
  pr2 err;
  raise (Parsing.Parse_error )

let failwith_xhp_ambiguity_percent info =
  let err = 
    "XHP: ambiguity on '%', please put a space after the percent in " ^
      Ast_php.string_of_info info
  in
  (*failwith err*)
  pr2 err;
  raise (Parsing.Parse_error )

(*****************************************************************************)
(* shortcuts *)
(*****************************************************************************)
(*s: AST builder *)
let mk_param typ s = 
  { p_type = typ;
    p_ref = None;
    p_name = DName s;
    p_default = None;
  }

let mk_e e = (e, Ast_php.noType())
(*e: AST builder *)
(*e: parser_php_mly_helper.ml *)
