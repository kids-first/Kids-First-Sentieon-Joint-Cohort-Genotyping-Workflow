cwlVersion: v1.2
class: CommandLineTool
id: fai_subset
doc: "subset index to first N contigs, and create output files names"

requirements:
  - class: ShellCommandRequirement
  - class: DockerRequirement
    dockerPull: "ubuntu:22.04"
  - class: ResourceRequirement
    ramMin: 4000
    coresMin: 2
  - class: InlineJavascriptRequirement

baseCommand: [head]
arguments:
  - position: 1
    shellQuote: false
    valueFrom: >-
      > subset_$(inputs.reference_fai.basename) && cut -f 1 subset_$(inputs.reference_fai.basename) | tee chr_list.txt | xargs -IN echo $(inputs.output_file_prefix)_N.vcf.gz > output_filename_list.txt
inputs:
  num_lines: { type: 'int?', doc: "Num lines from beginning to subset index on", default: 24, inputBinding: { position: 0, prefix: "-n"} }
  reference_fai: { type: File, doc: "Fasta reference index file to subset", inputBinding: {position: 0 } }
  output_file_prefix: string
outputs:
  reference_fai_subset:
    type: File
    outputBinding:
      glob: subset_$(inputs.reference_fai.basename)
  chr_list:
    type: File
    outputBinding:
      glob: "chr_list.txt"
  chr_array:
    type: 'string[]'
    outputBinding:
      glob: "chr_list.txt"
      loadContents: true
      outputEval: |
        $(self[0].contents.trim().split("\n"))
  output_filename_list:
    type: 'string[]'
    outputBinding:
      glob: "output_filename_list.txt"
      loadContents: true
      outputEval: |
        $(self[0].contents.trim().split("\n"))
