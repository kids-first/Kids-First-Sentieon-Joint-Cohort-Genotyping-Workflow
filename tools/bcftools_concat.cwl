cwlVersion: v1.2
class: CommandLineTool
doc: "Concatenate VCF file"
label: bcftools_concat
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(inputs.threads)
  ramMin: 16000
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/d3b-bixu/bcftools:1.20
- class: InlineJavascriptRequirement

baseCommand: [bcftools, concat]

inputs:
  threads: { type: 'int?', default: 8,
    inputBinding: { position: 1, prefix: "--threads"} }
  output: { type: string, doc: "Output filename",
    inputBinding: { position: 1, prefix: "--output"} }
  output_type: { type: ['null', {type: enum, name: output_type, symbols: ["b", "u", "v", "z"] } ], doc: "b: compressed BCF, u: uncompressed BCF, z: compressed VCF, v: uncompressed VCF [v]",
    inputBinding: { position: 1, prefix: "--output-type" } }
  write_index: { type: ['null', {type: enum, name: output_type, symbols: ["tbi", "csi"] } ], inputBinding: { position: 1, prefix: "--write-index=", separate: false }, doc: "Automatically index the output file" }
  input_vcfs: { type: 'File[]', secondaryFiles: ['.tbi'],
   inputBinding: { position: 2} }
outputs:
  merged_vcf: { type: File, secondaryFiles: ['.tbi'], outputBinding: { glob: '*.vcf.gz' } }
