cwlVersion: v1.2
class: Workflow
id: split-vcf-mini-workflow
doc: "A faux scatter workflow intended to have tasks built by sbg api"

requirements:
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement

inputs:
  input_vcf: { type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi'] }
  chr_list: { type: File }
  chr_array: { type: 'string[]', doc: "chr list as str array"}
  threads: { type: 'int?', default: 4 }
outputs:
  split_vcfs:
    type:
      type: array
      items:
        type: array
        items: File
    outputSource: split_vcf_by_chr/split_vcfs


steps:
  split_vcf_by_chr:
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    run: ../tools/bcftools_split_by_chr.cwl
    in:
      input_vcf: input_vcf
      chr_list: chr_list
      chr_array: chr_array
      threads: threads
    scatter: [input_vcf]
    out: [split_vcfs]

$namespaces:
  sbg: https://sevenbridges.com
