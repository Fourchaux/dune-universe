
(** Simple templating library.  It reads HTML files "with variables"
    and can either output an OCaml module (reusable template with some
    static checks) or perform substitutions and return the HTML.

    To parametrize the HTML, you can add the following arguments to
    any HTML tag:
    {v
    ml:content="<ident>"
    ml:content="<ident> <arg1> ... <argN>"
    ml:strip="true"   ml:strip="if empty"
    ml:replace="<ident>"					     v}

    - The argument [ml:content="v"] ([v] is any valid OCaml variable
      name) tells that the content of the HTML tag must be replaced by
      the HTML contained in the OCaml variable [v].
    - [ml:content="f v1 ... vN"] does the same but uses the return
      value of the OCaml function [f] on the list [[v1; ...; vN]] as
      the replacement HTML.
    - [ml:strip="true"] says that the HTML tag should be removed
      and replaced by the content.
    - [ml:strip="if empty"] says that the HTML tag should be removed
      only if the replacement content is empty.
    - [ml:replace="v"] is the same as [ml:content="v"] except that it
      adds [ml:strip="true"].

    A special value of <ident> is "include".  It serves to include the
    files passed as arguments and does not define a new function.

    Inside HTML arguments themselves, one can use
    - [${<ident>}] which is replaced by the content (a string) of the
      variable <indent>;
    - [${f v1 ... vN}] which is replaced by the string returned by the
      function [f] applied to the list [[v1; ...; vN]].

    @version 0.8
 *)

type html = Nethtml.document list

val compile_html :
  ?trailer_ml:string -> ?trailer_mli:string -> ?hide:string list ->
  ?module_name:string -> string -> unit
(** [compile_html fname] reads the HTML template file [fname]
    (typically a file with extension ".html") and creates an OCaml
    module with functions to fill the variables of the template.  The
    module will be in files [module_name].ml and [module_name].mli.

    @param module_name the name of the generated module, possibly
    preceded by a path to indicate where to save the module file.  By
    default, it is the basename of [fname] without its extension.

    @param trailer_ml additional code to be appended to the .ml file.
    This code can use the functions of the interface (without the
    module prefix) to set variables of the template.  You set a
    variable [v] using the value of a variable [v'], you should use
    the construction [Set.v tpl (fun t -> ... Get.v' t ...)] (which
    returns a copy of [tpl] with [v] set) to ensure that the value of
    [v'] at the time of rendering is used and not the one present in
    [tpl] when [v] is set.  This is important to maintain the
    independence of variables which may be set in any order (even if
    documented, the fact that a variable depends on others will lead
    to confusion and errors).  If you use [Get.v] inside [Set.v],
    [Get.v] will return the previous value of the variable [v].

    @param trailer_mli additional code to be appended to the .mli file.
    @param hide variables of the template that will not be present
    in the module interface.  This is only interesting if these
    variables are used in [trailer_ml] functions. *)

val compile : ?module_name:string -> string -> unit
(** [compile fname] does the same as [compile_html] except that
    trailer code is taken from [fname].ml and [fname].mli for the
    implementation and interface respectively.  Moreover, to hide
    the signature of a template variable, say "var", one can add a
    comment [(* \@hide var *)] in [fname].mli.  Special annotations
    are added to the generated module implementation and interface
    so errors point back to [fname].ml and [fname].mli respectively. *)


module Binding :
sig
  type t
  (** Mutable value holding a collection of mappings from
      names of variables to their values (both being strings). *)

  exception Not_found of string
  (** [Not_found var] is raised if the variable [var] is not found
      in the binding. *)

  val make : unit -> t
  (** [make()] returns a new empty collection of bindings. *)

  val copy : t -> t
  (** [copy b] returns a new collection of bindings initially
      containing the same bindings as [b]. *)

  val string : t -> string -> string -> unit
  (** [string b var s] add to the binding [var] -> [s] to [b]. *)

  val html : t -> string -> html -> unit
  (** [html b var h] add to the binding [var] -> [h] to [b]. *)

  val fun_html : t -> string ->
                 (< content: html; page: html > -> string list -> html) -> unit
  (** [fun_html b var f] add to the binding [var] -> [f] to [b].  At
      each occurrence of [var], [f ctx args] will be executed and its
      output will replace current HTML tag (or its content, depending
      on whether [ml:strip] was set or not).  [ctx] is an object
      giving some "context".  [ctx#content] is the html that is inside
      the tag and which is going to be replaced.  It can be used as a
      structured argument.  [ctx#page] returns the whole HTML page —
      this can be useful to generate a table of content for example. *)

  val fun_string : t -> string ->
                   (< page: html > -> string list -> string) -> unit
  (** [fun_string b var f] add to the binding [var] -> [f] to [b].
      See {!fun_html} for the arguments of [f]. *)

  val on_error : t -> (string -> string list -> exn -> unit) -> unit
  (** [on_error b f] when a function associated to a variable [v]
      applied to the arguments [a] raises an exception [e], call
      [f v a e].  The default value for [f] prints an error on [stderr]. *)
end

val subst : ?base: string -> Binding.t -> html -> html
(** [subst b html] return [html] where all variables are substituted
    according to the bindings [b].

    @param base All relative file names in "include" directives are
    considered to be relative to [base].  Default: the current working
    directory.
    @raise Invalid_argument if variable names are not valid or
    associated values do not correspond to their usage. *)

val read : ?base: string -> ?bindings:Binding.t -> string -> html
(** [read fname] reads the file [fname] and returns its content in a
    structured form.

    @param base All relative file names in "include" directives are
    considered to be relative to [base].  Default: the [Filename.dirname]
    of [fname].
    @param bindings if provided, perform the substitutions it
    mandates.  Otherwise, the "raw" HTML is returned (this is the
    default).

    @raise Sys_error if the file cannot be read. *)


(** {2 Utilities} *)

val write_html : ?doctype:bool -> ?perm: int -> html -> string -> unit
(** [write_html html fname] writes the textual representation of the
    [html] to the file [fname].

    @param doctype whether to output a doctype (default: [true]).
    @param perm the permissions of the created file (default: [0o644]).
                Whatever permissions you specify, the executable bits are
                removed.  *)

val body_of : html -> html
(** [body_of html] returns the body of the HTML document or the
    entire document if no body is found. *)

val title_of : html -> string
(** [title_of html] returns the title contained in [html] (if no
    title is present, it will return [""]). *)

module Path :
sig
  type t
  (** Path relative to a base directory. *)

  val base : t

  val from_base : t -> string
  (** The (normalized) path to the filename (the filename being
      excluded) relative to the base directory.  Returns [""] if we
      are in the base directory. *)

  val from_base_split : t -> string list
  (** The path to the filename (including it) relative to the base
      directory splitted into its components (see [Neturl] for the
      precise format). *)

  val filename : t -> string
  (** The filename the path points to.  The path designates a
      directory if and only if [filename] returns [""]. *)

  val to_base : t -> string
  (** The path from the directory of the filename to the base
      directory.  One can see it as the "inverse" of [from_base]. *)

  val in_base : t -> bool
  (** [in_base p] returns [true] if [p] is the base directory or a
      file in the base directory. *)

  val to_base_split : t -> string list
  (** The path from the directory of the filename to the base
      directory.  One can see it as the "inverse" of [from_base_split]. *)

  val parent : t -> t
  (** [parent p] returns the parent of [p].
     @raise Failure if it is the base path. *)

  val full : t -> string
  (** Returns a path that can be used to open the file (or query the
      directory). *)

  val language : t -> string
  (** [language p] returns the language of the filename based on the
     convention that it has the form "name.lang.ext". *)

  val description : t -> string
  (** [description p] returns the descriptive name for the file
      pointed by [p]. *)

  val concat_file : t -> string -> t

  val navigation : t -> (string * string) list
  (** [navigation p] returns the navigation information for the path
      [p].  It consists of a list of pairs [(name, path)] where
      [name] is a descriptive name of that directory of the path and
      [path] is the relative link to go from the location pointed by
      [p] to the directory.  If [filename p] is of the form
      index.html or index.<lang>.html, then only its directory is
      included in the navigation information.

      Descriptive names are based on the name of the directory or,
      if an index.<lang>.html file is present it is taken as its
      title (if any).  <lang> is determined according to the file
      pointed by [p] (if of the form name.<lang>.html). *)

  val translations : ?rel_dir: (string -> string -> string) ->
                     langs: string list -> t -> (string * string) list
  (** [translations langs p] returns a list of couples [(lang, url)]
      for all translations of the file pointed by the path [p].
      [langs] is the list of languages to examine, the first being the
      default one (files with no explicit language).

      @param rel_dir is a function so that [rel_dir lang l] gives the
      relative path from the base directory of the current language
      [lang] of the file [p] to the base directory of the translation
      in the language [l].  Default: [fun _ l -> "../" ^ l]. *)
end

val iter_html :
  ?langs:string list ->
  ?exts: string list -> ?filter:(Path.t -> bool) ->
  ?perm: int -> ?out_dir:(string -> string) -> ?out_ext:(string -> string) ->
  string -> (string -> Path.t -> html) -> unit
(** [iter_html base f] iterates [f lang file] on all HTML files under
    [base] (the argument of [f] is guaranteed to be a path to a file).
    The resulting HTML code is written under the directory
    [out_dir lang], the subpath begin the relative path of the file
    w.r.t. [base] and the filename is the original one with the
    language removed.
    @raise Invalid_argument if [base] is not a directory.

    @param lang the accepted languages.  The first one being the
    default one (for files that do not specify a language).
    @raise Invalid_argument if languages are not lowercase only.

    @param exts the allowed file extensions.  Defaut: [[".html"]].
    May be useful, ofr example, if you want to deal PHP pages.

    @param filter examine the file of dir iff the condition
    [filter rel_dir f] holds on the relative path [rel_dir] from [root] and
    final file or dir [f].  Default: accept all [.html] files.
    Files and dirs starting with a dot are {i always} excluded.

    @param out_dir a function s.t. [out_dir lang] gives the outpout
    directory used for the language [lang].  Default: the identity.

    @param out_ext a function to transform the output extension given
    the input one.  Default: the identity. *)

val relative_url_are_from_base : Path.t -> html -> html
(** [relative_url_are_from_base path html] prefix all relative URLs
    in [html] so that they are specified according to the directory
    given by [path] instead of the base path. *)

val email : ?args:(string * string) list -> ?content:html -> string -> html
(** [email e] return some HTML/javascript code to protect the email
    [e] from SPAM harvesters.  The email [e] may end with "?..." in
    order to specify options, e.g. [?subject=...].

    @param args arguments to the <a> HTML tag.  Default: [[]].

    @param content Tells whether the content of the email link is
    the email itself (no [content] specified, the default) or some
    other data. *)

val protect_emails : html -> html
(** [protect_emails html] changes all emails hrefs in [html] in
    order to make it more difficult for spammers to harvest them. *)


(** Simple cache with dependencies and timeout. *)
module Cache :
sig
  type 'a t
  (** A cache for elements of type 'a. *)

  val make : ?dep: 'b t -> ?new_if:('a t -> bool) -> ?timeout: float ->
             ?debug:bool ->
             string -> ('a option -> 'a) -> 'a t
  (** [make key f] create a new cache to hold the return value of [f]
      using the [key].  [f] is given its previously returned value if
      any — it may be less work to update it than recreating it
      afresh.  The disk cache will be updated when the program exits,
      so its content will persist across multiplie runs of the
      program.  The type ['a] must be marshal-able.

      @param timeout the number of seconds after which the cached
      value must be refreshed (running [f] again).  Default: [3600.].
      A non-positive value means no timeout.

      @param debug print messages on [stderr] about cache usage and
      refresh.  The string argument is a prefix to these messages to
      be able to distinguish different caches.  Default: [""] i.e.,
      no messages. *)

  val update : ?f:('a option -> 'a) -> 'a t -> unit
  (** [update t] update the cache immediately.  If [f] is given, first
      set the function generating values for the cache [t] to [f] and
      then update the cache by running [f]. *)

  val depend : 'a t -> dep:'b t -> unit
  (** [depend t t'] says that the cache [t] depends on the cache [t']
      i.e. that before updating [t], one must update [t']. *)

  val get : ?update: bool -> 'a t -> 'a
  (** Get the value stored in the cache.  This operation will update
      the cached value if necessary.

      @param update if [true], force an update.  Default: [false]. *)

  val result : ?dep: 'b t -> ?new_if:('a t -> bool) -> ?timeout: float ->
               ?debug:bool ->
               string -> ('a option -> 'a) -> 'a
  (** [result key f] is a convenience function equivalent to
      [get(make key f)]. *)

  val time : 'a t -> float
  (** The time of the last update of the cache.  Returns
      [neg_infinity] if the cache is not initialized. *)

  val key : 'a t -> string
  (** [key t] returns the key used to store the value. *)
;;
end
