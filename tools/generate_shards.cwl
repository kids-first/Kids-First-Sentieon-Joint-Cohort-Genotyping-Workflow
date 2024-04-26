cwlVersion: v1.2
class: CommandLineTool
label: generate_shards
$namespaces:
  sbg: https://sevenbridges.com

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: 1
- class: DockerRequirement
  dockerPull: python:3.9-slim-buster
- class: InitialWorkDirRequirement
  listing:
  - entryname: partition_genome.py
    entry:
      $include: ../scripts/partition_genome.py
- class: InlineJavascriptRequirement

inputs:
- id: reference_index
  label: Reference FAI index
  type: File
  inputBinding:
    position: 1
    shellQuote: true
  sbg:fileTypes: FAI
- id: num_parts
  label: Number of shards.
  type: int?
  inputBinding:
    position: 2
    shellQuote: true
    valueFrom:
      $(self) 200
- id: input_gvcf_list
  type: File
  inputBinding:
    position: 4
    shellQuote: true

outputs:
- id: bcftools_cmd
  type: File[]
  outputBinding:
    glob: bcftools_cmd_*.sh
- id: shard_interval
  type: File[]
  outputBinding:
    glob: shard_interval_*.txt

baseCommand:
- python
- partition_genome.py
arguments:
- position: 3
  valueFrom: "200"

