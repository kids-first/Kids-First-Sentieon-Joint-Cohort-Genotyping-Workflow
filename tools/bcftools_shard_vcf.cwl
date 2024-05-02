cwlVersion: v1.2
class: CommandLineTool
label: bcftools_shard_vcf
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(inputs.threads)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/brownm28/bcftools:1.19
- class: InlineJavascriptRequirement

baseCommand: []
arguments:
- position: 0
  shellQuote: false
  valueFrom: >-
    cat $(inputs.region_scatter_file.path) | xargs -ILN echo LN_$(inputs.input_vcf.nameroot) > region_scatter.tsv
- position: 1
  shellQuote: false
  valueFrom: >-
    && bcftools +scatter -S region_scatter.tsv -o ./ -O z
- position: 3
  shellQuote: false
  valueFrom: >-
    && ls *.vcf.gz | xargs -IFN -P $(inputs.threads) tabix FN

inputs:
  input_vcf: { type: File, secondaryFiles: ['.tbi'], inputBinding: {position: 2} }
  region_scatter_file: File
  threads: { type: 'int?', default: 2, inputBinding: {position: 1, prefix: "--threads"} }
outputs:
  sharded_vcfs: { type: 'File[]', secondaryFiles: ['.tbi'], outputBinding: { glob: '*.vcf.gz' } }
