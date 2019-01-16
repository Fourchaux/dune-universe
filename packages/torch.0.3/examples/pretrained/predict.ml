(* Evaluation using a pre-trained ResNet model.
   The pre-trained weight file can be found at:
     https://github.com/LaurentMazare/ocaml-torch/releases/download/v0.1-unstable/resnet18.ot
     https://github.com/LaurentMazare/ocaml-torch/releases/download/v0.1-unstable/densenet121.ot
*)
open Base
open Torch
open Torch_vision

let () =
  if Array.length Sys.argv <> 3
  then Printf.failwithf "usage: %s resnet18.ot input.png" Sys.argv.(0) ();
  let device =
    if Cuda.is_available ()
    then begin
      Stdio.printf "Using cuda, devices: %d\n%!" (Cuda.device_count ());
      Torch_core.Device.Cuda
    end else Torch_core.Device.Cpu
  in
  let image = Imagenet.load_image Sys.argv.(2) in
  let vs = Var_store.create ~name:"rn" ~device () in
  let model =
    match Caml.Filename.basename Sys.argv.(1) with
    | "vgg11.ot" -> Vgg.vgg11 vs ~num_classes:1000
    | "vgg13.ot" -> Vgg.vgg13 vs ~num_classes:1000
    | "vgg16.ot" -> Vgg.vgg16 vs ~num_classes:1000
    | "squeezenet1_0.ot" -> Squeezenet.squeezenet1_0 vs ~num_classes:1000
    | "squeezenet1_1.ot" -> Squeezenet.squeezenet1_1 vs ~num_classes:1000
    | "densenet121.ot" -> Densenet.densenet121 vs ~num_classes:1000
    | "densenet161.ot" -> Densenet.densenet161 vs ~num_classes:1000
    | "densenet169.ot" -> Densenet.densenet169 vs ~num_classes:1000
    | "resnet34.ot" -> Resnet.resnet34 vs ~num_classes:1000
    | "resnet50.ot" -> Resnet.resnet50 vs ~num_classes:1000
    | "resnet101.ot" -> Resnet.resnet101 vs ~num_classes:1000
    | "resnet152.ot" -> Resnet.resnet152 vs ~num_classes:1000
    | "resnet18.ot" -> Resnet.resnet18 vs ~num_classes:1000
    | "mobilenet-v2.ot" -> Mobilenet.v2 vs ~num_classes:1000
    | otherwise ->
      Printf.failwithf "unsupported model %s, try with resnet18.ot" otherwise ()
  in
  Stdio.printf "Loading weights from %s\n%!" Sys.argv.(1);
  Serialize.load_multi_ ~named_tensors:(Var_store.all_vars vs) ~filename:Sys.argv.(1);
  let probabilities =
    Layer.apply_ model image ~is_training:false
    |> Tensor.softmax ~dim:(-1)
  in
  Imagenet.Classes.top probabilities ~k:5
  |> List.iter ~f:(fun (name, probability) ->
    Stdio.printf "%s: %.2f%%\n%!" name (100. *. probability))
