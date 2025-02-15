(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   irmin-watcher 0.5.0
  ---------------------------------------------------------------------------*)

(** Irmin watchers.

    {e 0.5.0 — {{:https://github.com/mirage/irmin-watcher} homepage}} *)

val v : Core.t
(** [v id p f] is the listen hook calling [f] everytime a sub-path of [p] is
    modified. Return a function to call to remove the hook. Default to polling
    if no better solution is available. FSevents and Inotify backends are
    available. *)

val mode : [ `FSEvents | `Inotify | `Polling ]

type stats = { watchdogs : int; dispatches : int }

val hook : Core.hook
(** [hook t] is an {!Irmin.Watcher} compatible representation of {!v}. *)

val stats : unit -> stats
(** [stats ()] is a snapshot of [v]'s stats. *)

val set_polling_time : float -> unit
(** [set_polling_time f] set the polling interval to [f]. Only valid when
    [mode = `Polling]. *)

(*---------------------------------------------------------------------------
   Copyright (c) 2016 Thomas Gazagnaire

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
