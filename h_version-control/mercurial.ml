(* Yoann Padioleau
 * 
 * Copyright (C) 2009 Yoann Padioleau
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * version 2.1 as published by the Free Software Foundation, with the
 * special exception on linking described in file license.txt.
 * 
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
 * license.txt for more details.
 *)

open Common

open Lib_vcs 

(*****************************************************************************)
(* Commands *)
(*****************************************************************************)
(* ex: 
  stevel 7785c3469156 Thu Aug 30 00:13:38 2007 -0400: /*
*)

let annotate_regexp = 
  "^" ^ "[ \t]*\\([^ \t]+\\)[ \t]+" ^
    "\\([A-Za-z0-9]+\\)[ \t]+" ^
    "[A-Za-z]+" ^ "[ \t]+" ^
    "\\([A-Za-z]+\\)" ^ "[ \t]+" ^ (* month *)
    "\\([0-9]+\\)" ^ "[ \t]" ^ (* day *)
    "[0-9]+" ^ ":" ^
    "[0-9]+" ^ ":" ^
    "[0-9]+" ^ "[ \t]" ^ 
    "\\([0-9]+\\)" ^ "[ \t]" ^ "-" ^ (* year *)
    ".*" (* rest of line *)

    
let annotate2 ?(basedir="") filename = 
  (* 
     can add -f to follow rename and copy, in that case maybe add to add
      it to hg log too
     can add -u for user
  *)
  let cmd = (goto_dir basedir ^ "hg annotate -u -f -c -d "^filename^" 2>&1") in
  (* pr2 cmd; *)
  let xs = Common.cmd_to_list cmd in
  (*let ys = Common.cat (Common.filename_of_db (basedir,filename)) in*)

  let annots = 
    xs +> Common.map_filter (fun s -> 
      if s =~ annotate_regexp 
      then 
        let (author, commitid, month_str, day, year) = Common.matched5 s in
        Some (VersionId commitid, 
              Author author,
              Common.mk_date_dmy 
                (s_to_i day) 
                (Common.int_of_month (Common.month_of_string month_str))
                (s_to_i year))
      else begin 
        pr2 ("hg annotate wrong line: " ^ s);
        None
      end
    ) 
  in
  (* files lines are 1_based, so add this dummy 0 entry *)
  Array.of_list (dummy_annotation::annots)


let annotate ?basedir a = 
  Common.profile_code "Hg.annotate" (fun () -> annotate2 ?basedir a)

(* ------------------------------------------------------------------------ *)

let annotate_raw ?(basedir="") filename = 
  let cmd = (goto_dir basedir ^ "hg annotate -u -f -c -d "^filename^" 2>&1") in
  let xs = Common.cmd_to_list cmd in

  let annots = 
    xs +> Common.map_filter (fun s -> 
      if s =~ annotate_regexp 
      then 
        Some s
      else begin 
        (* pr2 ("hg annotate wrong line: " ^ s); *)
        None
      end
    ) 
  in
  Array.of_list (""::annots)



(* ------------------------------------------------------------------------ *)
(* ex:
date:        Thu Aug 30 00:13:38 2007 -0400
*)

let date_regexp = 
  "date:[ \t]+" ^
    "[A-Za-z]+" ^ "[ \t]+" ^
    "\\([A-Za-z]+\\)" ^ "[ \t]+" ^ (* month *)
    "\\([0-9]+\\)" ^ "[ \t]" ^ (* day *)
    "[0-9]+" ^ ":" ^
    "[0-9]+" ^ ":" ^
    "[0-9]+" ^ "[ \t]" ^ 
    "\\([0-9]+\\)" ^ "[ \t]" ^ "-" ^ (* year *)
    ".*" (* rest of line *)

let date_file_creation2 ?(basedir="") file = 

  let cmd = (goto_dir basedir ^ 
             "hg log -f "^file^" 2>&1")
  in
  let xs = Common.cmd_to_list cmd in
  let xs = List.rev xs in   (* could also hg log ... | tac *)
  
  xs +> Common.find_some (fun s -> 
    if s =~ date_regexp
    then 
      let (month_str, day, year) = Common.matched3 s in
      Some (Common.mk_date_dmy 
               (s_to_i day) 
               (Common.int_of_month (Common.month_of_string month_str))
               (s_to_i year))
    else None
  )


let date_file_creation ?basedir a = 
  Common.profile_code "Hg.date_file" (fun() -> date_file_creation2 ?basedir a)
