cwlVersion: v1.2
class: Workflow
id: test_shard_wf
label: Test Sharding Worfklow

requirements:
- class: ScatterFeatureRequirement

inputs:
  reference: { type: File, doc: "Reference fasta with associated fai index", secondaryFiles: ['.fai'], "sbg:fileTypes": "FA, FASTA"}
  fai_subset: { type: 'int?', doc: "Number of lines from head of fai to keep", default: 24 }
  num_shards: { type: 'int?', doc: "Nunber of shards to make", default: 20 }
  input_vcf: { type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi']}
  bcftools_cpu: { type: 'int?', default: 2}
outputs:
  sharded_vcfs:
    type:
      type: array
      items:
        type: array
        items: File
    outputSource: bcftools_shard_vcf/sharded_vcfs

steps:
  subset_fai:
    run: ../tools/fai_subset.cwl
    in:
      reference_fai:
        source: reference
        valueFrom: $(self.secondaryFiles[0])
      num_lines: fai_subset
    out: [reference_fai_subset]
  generate_shards:
    run: ../tools/shard_fai.cwl
    in:
      reference_index: subset_fai/reference_fai_subset
      num_shards: num_shards
    out: [shard_interval, bcftools_padded_scatter]
  bcftools_shard_vcf:
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    run: ../tools/bcftools_shard_vcf.cwl
    in:
      input_vcf: input_vcf
      region_scatter_file: generate_shards/bcftools_padded_scatter
      threads: bcftools_cpu
    scatter: [input_vcf]
    out: [sharded_vcfs]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: sbg:maxNumberOfParallelInstances
  value: 10