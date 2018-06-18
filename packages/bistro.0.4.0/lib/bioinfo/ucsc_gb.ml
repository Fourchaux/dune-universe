open Core_kernel
open Bistro.Std
open Bistro.EDSL
open Defs

type genome = [ `dm3 | `droSim1 | `hg18 | `hg19 | `hg38 | `mm8 | `mm9 | `mm10 | `sacCer2 ]

let string_of_genome = function
| `dm3 -> "dm3"
| `droSim1 -> "droSim1"
| `hg18 -> "hg18"
| `hg19 -> "hg19"
| `hg38 -> "hg38"
| `mm8 -> "mm8"
| `mm9 -> "mm9"
| `mm10 -> "mm10"
| `sacCer2 -> "sacCer2"

let genome_of_string = function
| "dm3" -> Some `dm3
| "droSim1" -> Some `droSim1
| "hg18" -> Some `hg18
| "hg19" -> Some `hg19
| "hg38" -> Some `hg38
| "mm8" -> Some `mm8
| "mm9" -> Some `mm9
| "mm10" -> Some `mm10
| "sacCer2" -> Some `sacCer2
| _ -> None

class type twobit = object
  method format : [`twobit]
  inherit binary_file
end

class type chrom_sizes = object
  inherit tsv
  method header : [`none]
  method f1 : string
  method f2 : int
end

class type bigBed = object
  method format : [`bigBed]
  inherit binary_file
end

class type bedGraph = object
  inherit bed3
  method f4 : float
end

class type wig = object
  method format : [`wig]
  inherit text_file
end

class type bigWig = object
  method format : [`bigWig]
  inherit binary_file
end

let env = docker_image ~account:"pveber" ~name:"ucsc-kent" ~tag:"330" ()


(** {5 Dealing with genome sequences} *)

let chromosome_sequence org chr =
  let org = string_of_genome org in
  let url =
    sprintf
      "ftp://hgdownload.cse.ucsc.edu/goldenPath/%s/chromosomes/%s.fa.gz"
      org chr
  in
  let descr = sprintf "ucsc_gb.chromosome_sequence(%s,%s)" org chr in
  workflow ~descr [
    wget ~dest:(tmp // "seq.fa.gz") url ;
    cmd "gunzip" [ tmp // "seq.fa.gz" ] ;
    cmd "mv" [ tmp // "seq.fa.gz" ; dest ] ;
  ]

let chromosome_sequences org =
  let org = string_of_genome org in
  workflow ~descr:(sprintf "ucsc_gb.chromosome_sequences(%s)" org) [
    mkdir_p dest ;
    cd dest ;
    wget (sprintf "ftp://hgdownload.cse.ucsc.edu/goldenPath/%s/chromosomes/*" org) ;
    cmd "gunzip" [ string "*.gz" ]
  ]

let genome_sequence org =
  let chr_seqs = chromosome_sequences org in
  workflow ~descr:"ucsc_gb.genome_sequence" [
    cmd "bash" [
      opt "-c" string "'shopt -s nullglob ; cat $0/{chr?.fa,chr??.fa,chr???.fa,chr????.fa} > $1'" ;
      dep chr_seqs ;
      dest
    ]
  ]

(* UGLY hack due to twoBitToFa: this tool requires that the 2bit
   sequence should be put in a file with extension 2bit. So I'm forced
   to create first a directory and then to select the unique file in it...*)
let genome_2bit_sequence_dir org =
  let org = string_of_genome org in
  workflow ~descr:(sprintf "ucsc_gb.2bit_sequence(%s)" org) [
    mkdir dest ;
    cd dest ;
    wget (sprintf "ftp://hgdownload.cse.ucsc.edu/goldenPath/%s/bigZips/%s.2bit" org org) ;
  ]

let genome_2bit_sequence org =
  (genome_2bit_sequence_dir org) / selector [ (string_of_genome org) ^ ".2bit" ]

(* (\* let wg_encode_crg_mappability n org = *\) *)
(* (\*   let url = sp "ftp://hgdownload.cse.ucsc.edu/gbdb/%s/bbi/wgEncodeCrgMapabilityAlign%dmer.bigWig" (string_of_genome org) n in *\) *)
(* (\*   Guizmin_unix.wget url *\) *)

(* (\* let wg_encode_crg_mappability_36 org = wg_encode_crg_mappability 36 org *\) *)
(* (\* let wg_encode_crg_mappability_40 org = wg_encode_crg_mappability 40 org *\) *)
(* (\* let wg_encode_crg_mappability_50 org = wg_encode_crg_mappability 50 org *\) *)
(* (\* let wg_encode_crg_mappability_75 org = wg_encode_crg_mappability 75 org *\) *)
(* (\* let wg_encode_crg_mappability_100 org = wg_encode_crg_mappability 100 org *\) *)

let twoBitToFa bed twobits =
  workflow ~descr:"ucsc_gb.twoBitToFa" [
    cmd ~env "twoBitToFa" [
      opt' "-bed" dep bed ;
      dep twobits ;
      dest
    ]
  ]

(* let fasta_of_bed org bed = *)
(*   twoBitToFa bed (genome_2bit_sequence org) *)

(* (\*   f2 *\) *)
(* (\*     "guizmin.bioinfo.ucsc.fasta_of_bed[1]" [] *\) *)
(* (\*     seq2b bed *\) *)
(* (\*     (fun env (File seq2b) (File bed) path -> *\) *)
(* (\*       twoBitToFa ~positions:(`bed bed) ~seq2b ~fa:path) *\) *)

(* (\* let fetch_sequences (File seq2b) locations = *\) *)
(* (\*   let open Core_kernel in *\) *)
(* (\*   Core_extended.Sys_utils.with_tmp ~pre:"gzm" ~suf:".seqList" (fun seqList -> *\) *)
(* (\*     Core_extended.Sys_utils.with_tmp ~pre:"gzm" ~suf:".fa" (fun fa -> *\) *)
(* (\*       (\\* Write locations to a file *\\) *\) *)
(* (\*       List.map locations Fungen.Location.to_string *\) *)
(* (\*       |> Out_channel.write_lines seqList ; *\) *)

(* (\*       (\\* run twoBitToFa *\\) *\) *)
(* (\*       twoBitToFa ~positions:(`seqList seqList) ~seq2b ~fa ; *\) *)

(* (\*       (\\* Parse the fasta file *\\) *\) *)
(* (\*       In_channel.with_file fa ~f:(fun ic -> *\) *)
(* (\*         Biocaml.fasta (in_channel_to_char_seq_item_stream_exn ic) *\) *)
(* (\*         /@ (fun x -> x.Biocaml.fasta sequence) *\) *)
(* (\*         |> Stream.to_list *\) *)
(* (\*       ) *\) *)
(* (\*     ) *\) *)
(* (\*   ) *\) *)

(** {5 Chromosome size and clipping} *)

let fetchChromSizes org =
  workflow ~descr:"ucsc_gb.fetchChromSizes" [
    cmd "fetchChromSizes" ~env ~stdout:dest [
      string (string_of_genome org) ;
    ]
  ]

let bedClip org bed =
  workflow ~descr:"ucsc_gb.bedClip" [
    cmd "bedClip -verbose=2" ~env [
      dep bed ;
      dep org ;
      dest ;
    ]
  ]




(** {5 Conversion between annotation file formats} *)

(* (\* let wig_of_bigWig bigWig = *\) *)
(* (\*   f1 *\) *)
(* (\*     "guizmin.bioinfo.ucsc.wig_of_bigWig[r1]" [] *\) *)
(* (\*     bigWig *\) *)
(* (\*     ( *\) *)
(* (\*       fun env (File bigWig) path -> *\) *)
(* (\* 	env.bash [ *\) *)
(* (\*           sp "bigWigToWig %s %s" bigWig path *\) *)
(* (\* 	] *\) *)
(* (\*     ) *\) *)

(* (\* let bigWig_of_wig ?(clip = false) org wig = *\) *)
(* (\*   let chrom_info = chrom_info org in *\) *)
(* (\*   f2 *\) *)
(* (\*     "guizmin.bioinfo.ucsc.bigWig_of_wig[r1]" [] *\) *)
(* (\*     chrom_info wig *\) *)
(* (\*     (fun env (File chrom_info) (File wig) path -> *\) *)
(* (\*       let clip = if clip then "-clip" else "" in *\) *)
(* (\*       env.sh "wigToBigWig %s %s %s %s" clip wig chrom_info path) *\) *)

let bedGraphToBigWig org bg =
  let tmp = seq [ tmp ; string "/sorted.bedGraph" ] in
  workflow ~descr:"bedGraphToBigWig" [
    cmd "sort" ~stdout:tmp [
      string "-k1,1" ;
      string "-k2,2n" ;
      dep bg ;
    ] ;
    cmd "bedGraphToBigWig" ~env [
      tmp ;
      dep (fetchChromSizes org) ;
      dest ;
    ]
  ]

let bedToBigBed_command org bed =
  let tmp = seq [ tmp ; string "/sorted.bed" ] in
  let sort =
    cmd "sort" ~stdout:tmp [
      string "-k1,1" ;
      string "-k2,2n" ;
      dep bed ;
    ] in
  let bedToBigBed =
    cmd "bedToBigBed" ~env [
      tmp ;
      dep (fetchChromSizes org) ;
      dest ;
    ]
  in
  [ sort ; bedToBigBed ]

let bedToBigBed org =
  let f bed =
    workflow
      ~descr:"ucsc_gb.bedToBigBed"
      (bedToBigBed_command org bed)
  in
  function
  | `bed3 bed -> f bed
  | `bed5 bed -> f bed

(* implements the following algorithm
   if bed is empty
   then touch target
   else bedToBigBed (sort bed)
*)
let bedToBigBed_failsafe org =
  let f bed =
    let test = cmd "test" [ string "! -s" ; dep bed ] in
    let touch = cmd "touch" [ dest ] in
    let cmd = or_list [
        and_list [ test ; touch ] ;
        and_list (bedToBigBed_command org bed) ;
      ] in
    workflow [ cmd ]
  in
  function
  | `bed3 bed -> f bed
  | `bed5 bed -> f bed


module Lift_over = struct
  class type chain_file = object
    inherit file
    method format : [`lift_over_chain_file]
  end

  let chain_file ~org_from ~org_to =
    let org_from = string_of_genome org_from
    and org_to = string_of_genome org_to in
    let url =
      sprintf
        "ftp://hgdownload.cse.ucsc.edu/goldenPath/%s/liftOver/%sTo%s.over.chain.gz"
        org_from org_from (String.capitalize org_to)
    in
    Unix_tools.(gunzip (wget url))

  let bed ~org_from ~org_to bed =
    let chain_file = chain_file ~org_from ~org_to in
    workflow ~descr:"ucsc.liftOver" [
      mkdir_p dest ;
      cmd "liftOver" ~env [
        dep bed ;
        dep chain_file ;
        dest // "mapped.bed" ;
        dest // "unmapped.bed" ;
      ] ;
    ]

  let mapped = selector ["mapped.bed"]
  let unmapped = selector ["unmapped.bed"]
end
