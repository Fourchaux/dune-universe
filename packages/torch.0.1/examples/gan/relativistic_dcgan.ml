(* Relativistic average LSGAN,
   see https://ajolicoeur.wordpress.com/RelativisticGAN/ *)
open Base
open Torch

let image_w = 64
let image_h = 64

let latent_dim = 128
let batch_size = 32
let learning_rate = 1e-4

let batches = 10**8

let create_generator vs =
  let tr2d ~stride ~padding ~input_dim n =
    Layer.conv_transpose2d_ vs ~ksize:4 ~stride ~padding ~use_bias:false ~input_dim n
  in
  let convt1 = tr2d ~stride:1 ~padding:0 ~input_dim:latent_dim 256 in
  let convt2 = tr2d ~stride:2 ~padding:1 ~input_dim:256 128 in
  let convt3 = tr2d ~stride:2 ~padding:1 ~input_dim:128 64 in
  let convt4 = tr2d ~stride:2 ~padding:1 ~input_dim:64 32 in
  let convt5 = tr2d ~stride:2 ~padding:1 ~input_dim:32 3 in
  fun rand_input ->
    Tensor.to_device rand_input ~device:(Var_store.device vs)
    |> Layer.apply convt1
    |> Tensor.const_batch_norm
    |> Tensor.relu
    |> Layer.apply convt2
    |> Tensor.const_batch_norm
    |> Tensor.relu
    |> Layer.apply convt3
    |> Tensor.const_batch_norm
    |> Tensor.relu
    |> Layer.apply convt4
    |> Tensor.const_batch_norm
    |> Tensor.relu
    |> Layer.apply convt5
    |> Tensor.tanh

let create_discriminator vs =
  let conv2d ~stride ~padding ~input_dim n =
    Layer.conv2d_ vs ~ksize:4 ~stride ~padding ~use_bias:false ~input_dim n
  in
  let conv1 = conv2d ~stride:2 ~padding:1 ~input_dim:3 32 in
  let conv2 = conv2d ~stride:2 ~padding:1 ~input_dim:32 64 in
  let conv3 = conv2d ~stride:2 ~padding:1 ~input_dim:64 128 in
  let conv4 = conv2d ~stride:2 ~padding:1 ~input_dim:128 256 in
  let conv5 = conv2d ~stride:1 ~padding:0 ~input_dim:256 1 in
  fun xs ->
    Tensor.to_device xs ~device:(Var_store.device vs)
    |> Layer.apply conv1
    |> Tensor.leaky_relu
    |> Layer.apply conv2
    |> Tensor.const_batch_norm
    |> Tensor.leaky_relu
    |> Layer.apply conv3
    |> Tensor.const_batch_norm
    |> Tensor.leaky_relu
    |> Layer.apply conv4
    |> Tensor.const_batch_norm
    |> Tensor.leaky_relu
    |> Layer.apply conv5
    |> Tensor.view ~size:[-1]

let rand () = Tensor.(f 2. * rand [ batch_size; latent_dim; 1; 1 ] - f 1.)

let write_samples samples ~filename =
  List.init 4 ~f:(fun i ->
      List.init 4 ~f:(fun j ->
          Tensor.narrow samples ~dim:0 ~start:(4*i + j) ~length:1)
      |> Tensor.cat ~dim:2)
  |> Tensor.cat ~dim:3
  |> Torch_vision.Image.write_image ~filename

let () =
  let device =
    if Cuda.is_available ()
    then begin
      Stdio.printf "Using cuda, devices: %d\n%!" (Cuda.device_count ());
      Cuda.set_benchmark_cudnn true;
      Torch_core.Device.Cuda
    end else Torch_core.Device.Cpu
  in

  let images = Serialize.load ~filename:Sys.argv.(1) in
  let train_size = Tensor.shape images |> List.hd_exn in

  let generator_vs = Var_store.create ~name:"gen" ~device () in
  let generator = create_generator generator_vs in
  let opt_g = Optimizer.adam generator_vs ~learning_rate in

  let discriminator_vs = Var_store.create ~name:"disc" ~device () in
  let discriminator = create_discriminator discriminator_vs in
  let opt_d = Optimizer.adam discriminator_vs ~learning_rate in

  let fixed_noise = rand () in

  Checkpointing.loop ~start_index:1 ~end_index:batches
    ~var_stores:[ generator_vs; discriminator_vs ]
    ~checkpoint_base:"relgan.ot"
    ~checkpoint_every:(`seconds 600.)
    (fun ~index:batch_idx ->
       let batch_images =
         let start = Int.(%) (batch_size * batch_idx) (train_size - batch_size) in
         Tensor.narrow images ~dim:0 ~start ~length:batch_size
         |> Tensor.to_type ~type_:Float
         |> fun xs -> Tensor.(xs / f 255.)
       in
       let discriminator_loss =
         let y_pred = discriminator Tensor.(f 2. * batch_images - f 1.) in
         let y_pred_fake = rand () |> generator |> discriminator in
         Tensor.(+)
           Tensor.(mse_loss y_pred (mean y_pred_fake + f 1.))
           Tensor.(mse_loss y_pred_fake (mean y_pred - f 1.))
       in
       Optimizer.backward_step ~loss:discriminator_loss opt_d;
       let generator_loss =
         let y_pred = discriminator Tensor.(f 2. * batch_images - f 1.) in
         let y_pred_fake = rand () |> generator |> discriminator in
         Tensor.(+)
           Tensor.(mse_loss y_pred (mean y_pred_fake - f 1.))
           Tensor.(mse_loss y_pred_fake (mean y_pred + f 1.))
       in
       Optimizer.backward_step ~loss:generator_loss opt_g;
       if batch_idx % 100 = 0
       then
         Stdio.printf "batch %4d    d-loss: %12.6f    g-loss: %12.6f\n%!"
           batch_idx
           (Tensor.float_value discriminator_loss)
           (Tensor.float_value generator_loss);
       Caml.Gc.full_major ();
       if batch_idx % 25000 = 0 || (batch_idx < 100000 && batch_idx % 5000 = 0)
       then
         generator fixed_noise
         |> Tensor.view ~size:[ -1; 3; image_h; image_w ]
         |> Tensor.to_device ~device:Cpu
         |> fun xs -> Tensor.((xs + f 1.) * f (255. /. 2.))
         |> Tensor.clamp_ ~min:(Scalar.float 0.) ~max:(Scalar.float 255.)
         |> Tensor.to_type ~type_:Uint8
         |> write_samples ~filename:(Printf.sprintf "out%d.png" batch_idx)
    )
