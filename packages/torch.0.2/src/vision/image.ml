open Base
open Torch

let resize_and_crop image_file ~f ~width ~height =
  let tmp_file = Caml.Filename.temp_file "imagenet-resize-crop" ".jpg" in
  let args =
    [ "-resize"; Printf.sprintf "%dx%d^" width height
    ; "-gravity"; "center"
    ; "-crop"; Printf.sprintf "%dx%d+0+0" width height
    ; Printf.sprintf "\"%s\"" image_file; tmp_file
    ]
  in
  let command = Printf.sprintf "convert %s" (String.concat args ~sep:" ") in
  match Unix.system command with
  | WEXITED 0 ->
    Exn.protect
      ~f:(fun () -> f tmp_file)
      ~finally:(fun () -> Unix.unlink tmp_file)
  | WEXITED i -> Or_error.errorf "%s returns a non-zero exit code %d" command i
  | WSIGNALED i -> Or_error.errorf "%s killed by signal %d" command i
  | WSTOPPED i -> Or_error.errorf "%s stopped %d" command i

let load_image_no_resize_and_crop image_file =
  Stb_image.load image_file
  |> Result.bind ~f:(fun (image : _ Stb_image.t) ->
    if image.channels = 3
    then
      Tensor.of_bigarray (Bigarray.genarray_of_array1 image.data)
      |> Tensor.view ~size:[ 1; image.height; image.width; image.channels ]
      |> Tensor.permute ~dims:[ 0; 3; 1; 2 ]
      |> Result.return
    else Error (`Msg (Printf.sprintf "%d channels <> 3" image.channels)))
  |> Result.map_error ~f:(fun (`Msg msg) -> Error.of_string msg)

let load_image ?resize image_file =
  match resize with
  | Some (width, height) ->
    resize_and_crop image_file ~f:load_image_no_resize_and_crop ~width ~height
  | None -> load_image_no_resize_and_crop image_file

let image_suffixes = [ ".jpg"; ".png" ]

let load_images ?resize dir =
  if not (Caml.Sys.is_directory dir)
  then Printf.failwithf "not a directory %s" dir ();
  let files = Caml.Sys.readdir dir |> Array.to_list in
  Stdio.printf "%d files found in %s\n%!" (List.length files) dir;
  List.filter_map files ~f:(fun filename ->
    if List.exists image_suffixes ~f:(fun suffix -> String.is_suffix filename ~suffix)
    then begin
      match load_image (Caml.Filename.concat dir filename) ?resize with
      | Ok image -> Some image
      | Error msg -> Stdio.printf "%s: %s\n%!" filename (Error.to_string_hum msg); None
    end else None)
  |> Tensor.cat ~dim:0

let load_dataset ~dir ~classes ~with_cache ~resize =
  let read () =
    let load tv s = load_images (Printf.sprintf "%s/%s/%s" dir tv s) ~resize in
    let load_tv tv =
      List.mapi classes ~f:(fun class_index class_dir ->
        let images = load tv class_dir in
        let labels = Tensor.zeros [ Tensor.shape images |> List.hd_exn ] ~kind:Int64 in
        Tensor.fill_int labels class_index;
        images, labels)
      |> List.unzip
      |> fun (images, labels) ->
      Tensor.cat images ~dim:0, Tensor.cat labels ~dim:0
    in
    let train_images, train_labels = load_tv "train" in
    let test_images, test_labels = load_tv "val" in
    { Dataset_helper.train_images
    ; train_labels
    ; test_images
    ; test_labels
    }
  in
  match with_cache with
  | None -> read ()
  | Some cache_file -> Dataset_helper.read_with_cache ~cache_file ~read

let write_image tensor ~filename =
  let tensor, height, width, channels =
    match Tensor.shape tensor with
    | [ 1; channels; b; c ] when channels = 1 || channels = 3 ->
        Tensor.reshape tensor ~shape:[ channels; b; c ], b, c, channels
    | [ channels; b; c ] when channels = 1 || channels = 3 -> tensor, b, c, channels
    | _ -> Printf.failwithf "unexpected shape %s" (Tensor.shape_str tensor) ()
  in
  let bigarray =
    Tensor.permute tensor ~dims:[ 1; 2; 0 ]
    |> Tensor.contiguous
    |> Tensor.view ~size:[ channels * height * width ]
    |> Tensor.to_type ~type_:Uint8
    |> Tensor.to_bigarray ~kind:Int8_unsigned
    |> Bigarray.array1_of_genarray
  in
  match String.rsplit2 filename ~on:'.' with
  | Some (_, "jpg") -> failwith "writing jpg images is not supported"
  | Some (_, "tga") -> Stb_image_write.tga filename bigarray ~w:width ~h:height ~c:channels
  | Some (_, "bmp") -> Stb_image_write.bmp filename bigarray ~w:width ~h:height ~c:channels
  | Some (_, "png") -> Stb_image_write.png filename bigarray ~w:width ~h:height ~c:channels
  | Some _
  | None -> Stb_image_write.png (filename ^ ".png") bigarray ~w:width ~h:height ~c:channels
