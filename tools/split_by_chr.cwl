cwlVersion: v1.2
class: CommandLineTool
label: split_by_chr
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(inputs.threads)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.02_cavatica
- class: InlineJavascriptRequirement
- class: EnvVarRequirement
  envDef:
  - envName: SENTIEON_LICENSE
    envValue: $(inputs.sentieon_license)

baseCommand: [bash -c]
arguments:
- position: 0
  shellQuote: false
  valueFrom: >-
    'set -eo pipefail; cut -f 1 $(inputs.reference_fai.path) | xargs -P $(inputs.threads) -ICHR bash -c "set -eo pipefail; bcftools view -r CHR $(inputs.input_vcf.path) | sentieon util vcfconvert - CHR_$(inputs.input_vcf.nameroot).g.vcf.gz"'

inputs:
  input_vcf: { type: File, secondaryFiles: ['.tbi'] }
  reference_fai: File
  threads: { type: 'int?', default: 3 }
  sentieon_license: { type: string, doc: "Sentieon license server IP and port"}
outputs:
  split_vcfs: { type: 'File[]', secondaryFiles: ['.tbi'], outputBinding: { glob: '*.vcf.gz' } }
