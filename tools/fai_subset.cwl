cwlVersion: v1.2
class: CommandLineTool
id: fai_subset
doc: "subset index to first N contigs"

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
      > subset_$(inputs.reference_fai.basename) && cut -f 1 subset_$(inputs.reference_fai.basename) > chr_list.txt
inputs:
  reference_fai: { type: File, doc: "Fasta reference index file to subset", inputBinding: {position: 0 } }
  num_lines: { type: 'int?', doc: "Num lines from beginning to subset index on", default: 24, inputBinding: { position: 0, prefix: "-n"} }
outputs:
  reference_fai_subset:
    type: File
    outputBinding:
      glob: subset_$(inputs.reference_fai.basename)
  chr_list:
    type: File
    outputBinding:
      glob: "chr_list.txt"
