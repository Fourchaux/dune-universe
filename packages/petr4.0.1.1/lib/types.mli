(* Copyright 2019-present Cornell University
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy
 * of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software 
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT 
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the 
 * License for the specific language governing permissions and limitations 
 * under the License. 
 *)

open Util

type 'a info = Info.t * 'a [@@deriving sexp, yojson]

val info : 'a info -> Info.t

module P4Int : sig 
  type pre_t = 
    { value: Bigint.t;
      width_signed: (int * bool) option }
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

module P4String : sig
  type t = string info
  [@@deriving sexp,yojson]
end

module rec Annotation : sig
  type pre_t = 
    { name: P4String.t; 
      args: Argument.t list }
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

and Parameter : sig 
  type pre_t = 
    { annotations: Annotation.t list;
      direction: Direction.t option;
      typ: Type.t;
      variable: P4String.t;
      opt_value: Expression.t option}
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

and Op : sig
  type pre_uni =
      Not 
    | BitNot
    | UMinus
  [@@deriving sexp,yojson]

  type uni = pre_uni info [@@deriving sexp,yojson]

  type pre_bin =
      Plus
    | PlusSat
    | Minus
    | MinusSat
    | Mul
    | Div
    | Mod
    | Shl
    | Shr
    | Le
    | Ge
    | Lt
    | Gt
    | Eq
    | NotEq
    | BitAnd
    | BitXor
    | BitOr
    | PlusPlus
    | And
    | Or
  [@@deriving sexp,yojson]

  type bin = pre_bin info [@@deriving sexp,yojson]
end

and Type : sig
  type pre_t =
      Bool
    | Error
    | IntType of Expression.t
    | BitType of Expression.t
    | Varbit of Expression.t
    | TopLevelType of P4String.t
    | TypeName of P4String.t
    | SpecializedType of
        { base: t; 
          args: t list }
    | HeaderStack of
        { header: t; 
          size:  Expression.t }
    | Tuple of t list
    | Void
    | DontCare 
  [@@deriving sexp,yojson]

  and t = pre_t info [@@deriving sexp,yojson]
end

and MethodPrototype : sig
  type pre_t =
      Constructor of 
        { annotations: Annotation.t list;
          name: P4String.t;
          params: Parameter.t list }
    | Method of
        { annotations: Annotation.t list;
          return: Type.t;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list}
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

and Argument : sig 
  type pre_t  =
      Expression of 
        { value: Expression.t }
    | KeyValue of
        { key: P4String.t;
          value: Expression.t }
    | Missing
  [@@deriving sexp,yojson]
   
  type t = pre_t info [@@deriving sexp,yojson]
end

and Direction : sig 
   type pre_t = 
       In
     | Out
     | InOut
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

and Expression : sig 
  type pre_t = 
      True
    | False
    | Int of P4Int.t
    | String of P4String.t
    | Name of P4String.t
    | TopLevel of P4String.t
    | ArrayAccess of 
        { array: t;
          index: t }
    | BitStringAccess of 
        { bits: t;
          lo: t;
          hi: t }
    | List of 
        { values: t list }
    | UnaryOp of 
        { op: Op.uni;
          arg: t }
    | BinaryOp of 
        { op: Op.bin;
          args: (t * t) }
    | Cast of 
        { typ: Type.t;
          expr: t }       
    | TypeMember of 
        { typ: Type.t;
          name: P4String.t }
    | ErrorMember of P4String.t
    | ExpressionMember of 
        { expr: t;
          name: P4String.t }
    | Ternary of 
        { cond: t;
          tru: t;
          fls: t }
    | FunctionCall of 
        { func: t;
          type_args: Type.t list;
          args: Argument.t list }
    | NamelessInstantiation of 
        { typ: Type.t;
          args: Argument.t list }
    | Mask of
        { expr: t;
          mask: t }
    | Range of 
        { lo: t;
          hi: t }
  [@@deriving sexp,yojson]

  and t = pre_t info [@@deriving sexp,yojson]
end

and TypeDeclaration : sig 
  type pre_t =
      Header of 
        { annotations: Annotation.t list; 
          name: P4String.t; 
          fields: field list }
    | HeaderUnion of 
        { annotations: Annotation.t list; 
          name: P4String.t; 
          fields: field list }
    | Struct of 
        { annotations: Annotation.t list; 
          name: P4String.t; 
          fields: field list }
    | Error of 
        { members: P4String.t list }
    | MatchKind of
        { members: P4String.t list }
    | Enum of 
        { annotations: Annotation.t list; 
          name: P4String.t; 
          members: P4String.t list }
    | SerializableEnum of 
        { annotations: Annotation.t list; 
          typ: Type.t;
          name: P4String.t; 
          members: (P4String.t * Expression.t) list }
    | ExternObject of 
        { annotations: Annotation.t list;
          name: P4String.t;
          type_params: P4String.t list;
          methods: MethodPrototype.t list }
    | TypeDef of 
        { annotations: Annotation.t list;
          name: P4String.t;
          typ_or_decl: (Type.t, t) alternative }
    | NewType of 
        { annotations: Annotation.t list;
          name: P4String.t;
          typ_or_decl: (Type.t, t) alternative }
    | ControlType of 
        { annotations: Annotation.t list;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list }
    | ParserType of 
        { annotations: Annotation.t list;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list }
    | PackageType of 
        { annotations: Annotation.t list;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list }
  [@@deriving sexp,yojson]

  and t = pre_t info [@@deriving sexp,yojson]

  and pre_field = 
      { annotations: Annotation.t list;
        typ: Type.t;
        name: P4String.t } [@@deriving sexp,yojson]
    
  and field = pre_field info [@@deriving sexp,yojson]

  val name : t -> P4String.t

end

and Table : sig
  type pre_action_ref = 
    { annotations: Annotation.t list;
      name: P4String.t;
      args: Argument.t list }
  [@@deriving sexp,yojson]

  type action_ref = pre_action_ref info [@@deriving sexp,yojson]

  type pre_key = 
    { annotations: Annotation.t list;
      key: Expression.t;
      match_kind: P4String.t }
  [@@deriving sexp,yojson]                

  type key = pre_key info [@@deriving sexp,yojson]

  type pre_entry = 
    { annotations: Annotation.t list;
      matches: Match.t list;
      action: action_ref }
  [@@deriving sexp,yojson]      

  type entry = pre_entry info [@@deriving sexp,yojson]

  type pre_property = 
      Key of 
        { keys: key list }
    | Actions of 
        { actions: action_ref list }
    | Entries of 
        { entries: entry list }      
    | Custom of
        { annotations: Annotation.t list;
          const: bool;
          name: P4String.t;
          value: Expression.t }
  [@@deriving sexp,yojson]

  type property = pre_property info [@@deriving sexp,yojson]
end

and Match : sig 
  type pre_t =  
      Default
    | DontCare
    | Expression of 
        { expr: Expression.t }
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

and Parser : sig

  type pre_case = 
    { matches: Match.t list;
      next: P4String.t }
  [@@deriving sexp,yojson]      

  type case = pre_case info [@@deriving sexp,yojson]

  type pre_transition =
      Direct of
        { next: P4String.t }
    | Select of 
        { exprs: Expression.t list;
          cases: case list }
  [@@deriving sexp,yojson]      

  type transition = pre_transition info

  type pre_state = 
    { annotations: Annotation.t list;
      name: P4String.t;
      statements: Statement.t list;
      transition: transition }
  [@@deriving sexp,yojson]      

  type state = pre_state info [@@deriving sexp,yojson]
end

and Declaration : sig 
  type pre_t =
      Constant of 
        { annotations: Annotation.t list;
          typ: Type.t;
          name: P4String.t;
          value: Expression.t }
    | Instantiation of
        { annotations: Annotation.t list;
          typ: Type.t;
          args: Argument.t list;
          name: P4String.t }
    | Parser of 
        { annotations: Annotation.t list;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list;
          constructor_params: Parameter.t list;
          locals: t list;
          states: Parser.state list }
    | Control of
        { annotations: Annotation.t list;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list;
          constructor_params: Parameter.t list;
          locals: t list;
          apply: Block.t }
    | Function of
        { return: Type.t;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list;
          body: Block.t }
    | ExternFunction of
        { annotations: Annotation.t list;
          return: Type.t;
          name: P4String.t;
          type_params: P4String.t list;
          params: Parameter.t list }
    | Variable of 
        { annotations: Annotation.t list;
          typ: Type.t;
          name: P4String.t;
          init: Expression.t option }
    | ValueSet of
        { annotations: Annotation.t list;
          typ: Type.t;
          size: Expression.t;
          name: P4String.t }
    | Action of
        { annotations: Annotation.t list;
          name: P4String.t;
          params: Parameter.t list;
          body: Block.t }
    | Table of 
        { annotations: Annotation.t list;
          name: P4String.t;
          properties: Table.property list }
  [@@deriving sexp,yojson]

  and t = pre_t info [@@deriving sexp,yojson]

  val name : t -> P4String.t
end

and Statement : sig
  type pre_switch_label = 
      Default
    | Name of P4String.t
  [@@deriving sexp,yojson]

  type switch_label = pre_switch_label info [@@deriving sexp,yojson]

  type pre_switch_case =
    Action of 
      { label: switch_label;
        code: Block.t }
  | FallThrough of
      { label: switch_label }
  [@@deriving sexp,yojson]

  type switch_case = pre_switch_case info [@@deriving sexp,yojson]

  type pre_t = 
      MethodCall of
      { func: Expression.t;
        type_args: Type.t list;
        args: Argument.t list }
    | Assignment of 
        { lhs: Expression.t;
          rhs: Expression.t }          
    | DirectApplication of
        { typ: Type.t;
          args: Argument.t list }
    | Conditional of
        { cond: Expression.t;
          tru: t;
          fls: t option }
    | BlockStatement of 
        { block: Block.t }
    | Exit
    | EmptyStatement 
    | Return of 
        { expr: Expression.t option }
    | Switch of 
        { expr: Expression.t;
          cases: switch_case list }
    | DeclarationStatement of 
        { decl: Declaration.t }
  [@@deriving sexp,yojson]
  
  and t = pre_t info [@@deriving sexp,yojson]
end

and Block : sig
  type pre_t = 
    { annotations: Annotation.t list;
      statements: Statement.t list }
  [@@deriving sexp,yojson]

  type t = pre_t info [@@deriving sexp,yojson]
end

and TopDeclaration : sig
  type t = 
      TypeDeclaration of TypeDeclaration.t
    | Declaration of Declaration.t
  [@@deriving sexp,yojson]

end 

type program = 
  Program of TopDeclaration.t list [@@deriving sexp,yojson,yojson]
