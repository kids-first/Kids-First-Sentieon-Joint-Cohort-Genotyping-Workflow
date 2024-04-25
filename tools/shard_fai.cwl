cwlVersion: v1.2
class: CommandLineTool
label: shard_fai
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
  - entryname: create_shards.py
    entry:
      $include: ../scripts/create_shards.py
- class: InlineJavascriptRequirement

baseCommand: [python, create_shards.py]
arguments:
- position: 3
  shellQuote: false
  valueFrom: "200"

inputs:
  reference_index: { type: File, doc: "fasta index file to shard", inputBinding: { position: 0 }, "sbg:fileTypes": FAI }
  num_shards: { type: 'int?', inputBinding: {position: 2}, default: 60}
outputs:
  shard_interval: { type: 'File[]', outputBinding: { glob: shard_interval_*.txt } }
  bcftools_padded_scatter: { type: File, outputBinding: { glob: bcftools_padded_scatter.tsv } }
