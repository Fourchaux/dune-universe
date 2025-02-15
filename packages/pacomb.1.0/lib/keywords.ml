module type Spec =
  sig
    val id_charset : Charset.t
    val reserved : string list
  end

module Make(S : Spec) =
  struct
    let reserved : string list ref = ref S.reserved

    let mem : string -> bool = fun s ->
      List.mem s !reserved

    let reserve : string -> unit = fun s ->
      if mem s then invalid_arg "already reserved";
      reserved := s :: !reserved

    let check : string -> unit = fun s ->
      if List.mem s !reserved then Lex.give_up ()

    let special : string -> unit Grammar.t = fun s ->
      if s = "" then invalid_arg "empty word";
      let fn str pos =
        let str = ref str in
        let pos = ref pos in
        for i = 0 to String.length s - 1 do
          let (c, str', pos') = Input.read !str !pos in
          if c <> s.[i] then Lex.give_up ();
          str := str'; pos := pos'
        done;
        let c = Input.get !str !pos in
        if Charset.mem S.id_charset c then Lex.give_up ();
        ((), !str, !pos)
      in
      Grammar.term { n = s; f = fn ; c = Charset.singleton s.[0] }

    let create : string -> unit Grammar.t = fun s ->
      if mem s then invalid_arg "keyword already defined";
      reserve s; special s
  end
