cwlVersion: v1.2
class: CommandLineTool
label: bcftools_shard_vcf

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(inputs.threads)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/brownm28/bcftools:1.19
- class: InlineJavascriptRequirement

baseCommand: [bash -c]
arguments:
- position: 0
  shellQuote: false
  valueFrom: >-
   'source
- position: 1
  shellQuote: false
  valueFrom: >-
    && bcftools view -O z
- position: 3
  shellQuote: false
  valueFrom: >-
    '
inputs:
  input_s3: { type: string, inputBinding: {position: 2 } }
  aws_cred_file: { type: File, inputBinding: { position: 0} }
  region: { type: string, inputBinding: { position: 1, prefix: "-r"}}
  threads: { type: 'int?', default: 2, inputBinding: {position: 1, prefix: "--threads"} }
  output_file_name: { type: 'string?', default: "slice.vcf.gz", inputBinding: { position: 1, prefix: "-o"} }
outputs:
  vcf_slice: { type: File, outputBinding: { glob: '*.vcf.gz' } }
