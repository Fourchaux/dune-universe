let read threshold x =
  let open Asak.Lambda_hash in
  let prefix =
    try
      let start =
        try String.rindex x '/' + 1
        with Not_found -> 0 in
      String.sub x start (String.length x - start)
    with
    | Not_found -> "" in
  let chan = open_in x in
  let lambdas : (string * Lambda.lambda) list = Marshal.from_channel chan in
  let lambdas =
    Asak.Lambda_hash.map_snd
      (fun x -> Asak.Lambda_normalization.(normalize_local_variables (inline_all x)))
      lambdas in
  let res =
    List.rev_map (fun (name,xs) -> prefix ^ ":" ^ name, xs) @@
      hash_all {should_sort=false;hash_var=true} threshold
        lambdas in
  close_in chan;
  res

let get_args () =
  match Array.to_list Sys.argv with
  | _::filename::nb::xs -> (filename,int_of_string nb,xs)
  | _ -> failwith "Specify a threshold."

let () =
  let (filename,threshold,xs) = get_args () in
  let read = read threshold in
  let all_hashs =
    List.fold_left
      (fun acc x -> read x @ acc) [] xs in
  let all_cluster = Asak.Clustering.cluster all_hashs in
  let chan = open_out_bin filename in
  Marshal.to_channel chan all_cluster [];
  close_out chan;
  Asak.Clustering.print_cluster (fun x -> x) all_cluster
