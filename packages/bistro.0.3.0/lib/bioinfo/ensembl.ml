open Core_kernel.Std
open Bistro.Std
open Bistro.EDSL
open Defs

type species = [
  | `homo_sapiens
  | `mus_musculus
]

let ucsc_reference_genome ~release ~species =
  match species with
  | `mus_musculus when 63 <= release && release <= 65 -> `mm9
  | `mus_musculus when 81 <= release && release <= 86 -> `mm10
  | `homo_sapiens when release = 71 -> `hg19
  | `homo_sapiens when 84 <= release && release <= 87 -> `hg38
  | _ -> failwith "Ensembl.ucsc_reference_genome: unknown release for this species"

(* acronym of the lab where the species was sequenced *)
let lab_label_of_genome = function
  | `hg19 -> "GRCh37"
  | `hg38 -> "GRCh38"
  | `mm9 -> "NCBIM37"
  | `mm10 -> "GRCm38"

let string_of_species = function
  | `homo_sapiens -> "homo_sapiens"
  | `mus_musculus -> "mus_musculus"

let ucsc_chr_names_gtf gff =
  workflow ~descr:"ensembl.ucsc_chr_names_gtf" [
    pipe [
      cmd "gawk" [
        string "'{print \"chr\" $0}'" ;
        dep gff
      ] ;
      cmd "sed" [ string "'s/chrMT/chrM/g'" ] ;
      cmd "sed" [ string "'s/chr#/#/g'" ] ~stdout:dest
    ]
  ]

let gff ?(chr_name = `ensembl) ~release ~species =
  let url =
    sprintf "ftp://ftp.ensembl.org/pub/release-%d/gff3/%s/%s.%s.%d.gff3.gz"
      release (string_of_species species)
      (String.capitalize (string_of_species species))
      (lab_label_of_genome (ucsc_reference_genome ~release ~species)) release
  in
  let gff = Unix_tools.(gunzip (wget url)) in
  match chr_name with
  | `ensembl -> gff
  | `ucsc -> ucsc_chr_names_gtf gff


let gtf ?(chr_name = `ensembl) ~release ~species =
  let url =
    sprintf "ftp://ftp.ensembl.org/pub/release-%d/gtf/%s/%s.%s.%d.gtf.gz"
      release (string_of_species species)
      (String.capitalize (string_of_species species))
      (lab_label_of_genome (ucsc_reference_genome ~release ~species)) release
  in
  let f = match chr_name with
    | `ensembl -> ident
    | `ucsc -> ucsc_chr_names_gtf
  in
  f @@ Unix_tools.(gunzip (wget url))
