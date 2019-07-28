type t = Rfc2045.mechanism

let pp ppf = function
  | `Bit7 -> Fmt.string ppf "7bit"
  | `Bit8 -> Fmt.string ppf "8bit"
  | `Binary -> Fmt.string ppf "binary"
  | `Quoted_printable -> Fmt.string ppf "quoted-printable"
  | `Base64 -> Fmt.string ppf "base64"
  | `Ietf_token token -> Fmt.pf ppf "ietf:%s" token
  | `X_token token -> Fmt.pf ppf "x:%s" token

let default = `Bit7
let bit8 = `Bit8
let bit7 = `Bit7
let binary = `Binary
let quoted_printable = `Quoted_printable
let base64 = `Base64

let of_string = function
  | "7bit" -> Ok `Bit7
  | "8bit" -> Ok `Bit8
  | "binary" -> Ok `Binary
  | "quoted-printable" -> Ok `Quoted_printable
  | "base64" -> Ok `Base64
  | x -> Rresult.R.error_msgf "Invalid MIME encoding: %s" x
(* TODO:
   - let the user to craft an extension token.
   - check IETF database *)

let equal a b = match a, b with
  | `Bit7, `Bit7 -> true
  | `Bit8, `Bit8 -> true
  | `Binary, `Binary -> true
  | `Quoted_printable, `Quoted_printable -> true
  | `Base64, `Base64 -> true
  | `Ietf_token a, `Ietf_token b -> String.(equal (lowercase_ascii a) (lowercase_ascii b))
  | `X_token a, `X_token b -> String.(equal (lowercase_ascii a) (lowercase_ascii b))
  | _, _ -> false

module Encoder = struct
  open Encoder

  let mechanism ppf = function
    | `Bit7 -> string ppf "7bit"
    | `Bit8 -> string ppf "8bit"
    | `Binary -> string ppf "binary"
    | `Quoted_printable -> string ppf "quoted-printable"
    | `Base64 -> string ppf "base64"
    | `Ietf_token x -> string ppf x
    | `X_token x -> eval ppf [ string $ "X-"; !!string ] x
end
