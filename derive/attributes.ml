open Ppxlib

type type_attributes = {
  rename : string;
  mode :
    [ `tag of string
    | `tag_and_content of string * string
    | `untagged
    | `normal ];
  rename_all :
    [ `lowercase
    | `UPPERCASE
    | `camelCase
    | `PascalCase
    | `snake_case
    | `SCREAMING_SNAKE_CASE
    | `kebab_case
    | `SCREAMING_KEBAB_CASE ]
    option;
  error_on_unknown_fields : bool;
}

type variant_attributes = {
  rename : string;
  should_skip : [ `skip_serializing | `skip_deserializing | `always | `never ];
  is_catch_all : bool;
}

type field_attributes = {
  name : string;
  presence : [ `required | `optional | `with_default of Parsetree.expression ];
  should_skip :
    [ `skip_serializing_if of string
    | `skip_deserializing_if of string
    | `always
    | `never ];
}

let of_field_attributes lbl =
  let open Ppxlib in
  let name = ref lbl.pld_name.txt in
  let should_skip = ref `never in
  let presence =
    ref
      (match lbl.pld_type.ptyp_desc with
      | Ptyp_constr ({ txt = Lident "option"; _ }, _) -> `optional
      | _ -> `required)
  in
  let () =
    match lbl.pld_attributes with
    | [
     {
       attr_name = { txt = "serde"; _ };
       attr_payload =
         PStr
           [
             {
               pstr_desc =
                 Pstr_eval ({ pexp_desc = Pexp_record (fields, _); _ }, _);
               _;
             };
           ];
       _;
     };
    ] ->
        List.iter
          (fun (label, expr) ->
            match (label, expr) with
            | ( { txt = Lident "rename"; _ },
                { pexp_desc = Pexp_constant (Pconst_string (s, _, _)); _ } ) ->
                name := s;
                ()
            | { txt = Lident "default"; _ }, expr ->
                presence := `with_default expr;
                ()
            | _ -> ())
          fields
    | _ -> ()
  in

  (lbl, { name = !name; presence = !presence; should_skip = !should_skip })
