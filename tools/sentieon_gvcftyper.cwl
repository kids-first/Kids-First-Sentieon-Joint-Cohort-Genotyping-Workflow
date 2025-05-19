cwlVersion: v1.2
class: CommandLineTool
id: sentieon-gvcftyper
label: Sentieon_GVCFtyper
doc: |-
  The Sentieon **GVCFtyper** binary performs joint genotyping using One or more GVCFs.

  ### Notes:
  * Set `--genotype_model=coalescent --emit_conf=10 --call_conf=10` to match GATK 3.7, 3.8, 4.0.
  * Set `--genotype_model=multinomial --emit_conf=30 --call_conf=30` to match GATK 4.1. (default)

requirements:
  - class: ShellCommandRequirement
  - class: ResourceRequirement
    coresMin: $(inputs.cpu_per_job)
    ramMin: $(inputs.mem_per_job * 1000)
  - class: DockerRequirement
    dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.02_cavatica_patched
  - class: EnvVarRequirement
    envDef:
    - envName: SENTIEON_LICENSE
      envValue: $(inputs.sentieon_license)
    - envName: VCFCACHE_BLOCKSIZE
      envValue: "4096"
  - class: InlineJavascriptRequirement
  - class: InitialWorkDirRequirement
    listing:
      - entryname: gvcf_list.txt
        entry:
          $(inputs.input_gvcf_files.map(function(e) { return e.path }).join('\n'))

$namespaces:
  sbg: https://sevenbridges.com

baseCommand: [sentieon, driver]
arguments:
  - position: 10
    shellQuote: false
    valueFrom: >-
      --traverse_param 10000/200
  - position: 100
    shellQuote: false
    valueFrom: >-
      --algo GVCFtyper
  - position: 300
    shellQuote: false
    valueFrom: >-
      - < gvcf_list.txt

inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000 " }
  input_gvcf_files: { type: 'File[]', secondaryFiles: ['.tbi?', '.idx?'], "sbg:fileTypes": "VCF, VCF.GZ, GVCF, GVCF.GZ" }
  reference: { type: File, secondaryFiles: ['.fai'] , doc: "Reference fasta, need index in same location", inputBinding: { position: 11, prefix: "-r" }, "sbg:fileTypes": "FA, FASTA" }
  shard:
    type: 'File?'
    loadContents: true
    inputBinding:
      position: 12
      valueFrom: |
        --shard $(self.contents)
      shellQuote: false
  interval: { type: 'string?', inputBinding: { position: 12, prefix: "--interval" } }
  dbSNP: { type: 'File?', secondaryFiles: ['.tbi?', '.idx?'], doc: "Supplying this file will annotate variants with their dbSNP refSNP ID numbers. (optional)",
    inputBinding: { position: 101, prefix: "-d" } }
  emit_mode: { type: ['null', {type: enum, name: emit_mode, symbols: ["variant", "confident", "all"]} ],  doc: "Emit mode: variant, confident or all (default: variant)",
    default: "variant", inputBinding: { position: 101, prefix: "--emit_mode" } }
  call_conf: { type: 'int?', doc: "Call confidence level (default: 30), set to 10 for coalescent mode",
    default: 30, inputBinding: { position: 101, prefix: "--call_conf" } }
  emit_conf: { type: 'int?', doc: "Emit confidence level (default: 30), set to 10 for coalescent mode",
    default: 30, inputBinding: { position: 101, prefix: "--emit_conf" } }
  genotype_model: { type: ['null', {type: enum, name: genotype_model, symbols: ["coalescent", "multinomial"]} ],  doc: "While the coalescent mode is theoretically more accuracy for smaller cohorts, the multinomial mode is equally accurate with large cohorts and scales better with a very large numbers of samples.",
    default: "multinomial", inputBinding: { position: 101, prefix: "--genotype_model" } }
  max_alt_alleles: { type: 'int?', doc: "Maximum number of alternate alleles (default: 100)",
    default: 100, inputBinding: { position: 101, prefix: "--max_alt_alleles" } }
  output_file_name: { type: 'string?', doc: "The output VCF file name. Must end with '.vcf.gz'",
    default: "output.vcf.gz", inputBinding: { position: 200} }
  cpu_per_job: { type: 'int?', doc: "Num cpus to use for GVCFtyper", default: 32 }
  mem_per_job: { type: 'int?', doc: "Memory to allow GVCFtyper to use in GB", default: 32 }

outputs:
  output_vcf: { type: File, secondaryFiles: ['.tbi'], outputBinding: { glob: "*.vcf.gz" } }


