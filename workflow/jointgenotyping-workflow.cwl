cwlVersion: v1.2
class: Workflow
label: Sentieon Distributed Joint Genotyping Workflow

requirements:
- class: ScatterFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement
- class: MultipleInputFeatureRequirement

$namespaces:
  sbg: https://sevenbridges.com

hints:
- class: sbg:maxNumberOfParallelInstances
  value: 128

inputs:
- id: reference
  label: Reference
  doc: Reference fasta with associated fai index
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  - pattern: ^.dict
    required: false
  sbg:fileTypes: FA, FASTA
- id: input_gvcf_list
  label: Input GVCF
  doc: |-
     Supply the URLs of both the gVCFs and their index files
  type: File
- id: dbSNP
  label: dbSNP VCF file
  doc: |-
    Supplying this file will annotate variants with their dbSNP refSNP ID numbers. (optional)
  type: File?
  secondaryFiles:
  - pattern: .tbi
    required: false
  - pattern: .idx
    required: false
- id: sentieon_license
  label: Sentieon license
  doc: License server host and port
  type: string
- id: AWS_ACCESS_KEY_ID
  type: string?
- id: AWS_SECRET_ACCESS_KEY
  type: string?
- id: AWS_SESSION_TOKEN
  type: string?
- id: num_parts
  label: Number of shards.
  type: int?
- id: call_conf
  label: Call confidence level
  type: int?
- id: emit_conf
  label: Emit confidence level
  type: int?  
- id: genotype_model
  label: Genotype model
  doc: |-
    Genotype model: coalescent or multinomial. 
    While the coalescent mode is theoretically more accurate for smaller cohorts, the multinomial mode is equally accurate with large cohorts and scales better with a very large number of samples.
  type:
  - 'null'
  - name: genotype_model
    type: enum
    symbols:
    - coalescent
    - multinomial
- id: output_file_name
  label: Output file name
  doc: The output VCF file name. Must end with ".vcf.gz".
  type: string?

outputs:
- id: output_vcf
  type: File
  secondaryFiles:
  - pattern: .tbi
    required: true
  outputSource:
  - sentieon_gvcftyper_merge/output_vcf
  sbg:fileTypes: VCF.GZ

steps:
- id: fai_cleanup
  in: 
  - id: reference
    source: reference
  out:
  - id:  reference_fai
  hints:
  - class: 'sbg:AWSInstanceType'
    value: c4.large
  run: 
    cwlVersion: v1.2
    class: CommandLineTool
    requirements:
      - class: InlineJavascriptRequirement
    inputs:
    - id: reference
      type: File
      secondaryFiles:
      - {pattern: .fai, required: true}
    outputs:
    - id: reference_fai
      type: File
      outputBinding:
        glob: '*.fai'
    arguments:
    - position: 1
      shellQuote: false
      valueFrom: |- 
        head -n 25 $(inputs.reference.secondaryFiles[0].path) > $(inputs.reference.secondaryFiles[0].path.split('/').reverse()[0])
- id: generate_shards
  in:
  - id: reference_index
    source: fai_cleanup/reference_fai
  - id: num_parts
    source: num_parts
  - id: input_gvcf_list
    source: input_gvcf_list
  run: ../tools/generate_shards.cwl
  hints:
  - class: 'sbg:AWSInstanceType'
    value: c4.large
  out:
  - id: bcftools_cmd
  - id: shard_interval
- id: sentieon_gvcftyper_distributed 
  hints:
  - class: 'sbg:AWSInstanceType'
    value: c5.12xlarge
  in:
  - id: sentieon_license
    source: sentieon_license
  - id: AWS_ACCESS_KEY_ID
    source: AWS_ACCESS_KEY_ID
  - id: AWS_SECRET_ACCESS_KEY
    source: AWS_SECRET_ACCESS_KEY
  - id: AWS_SESSION_TOKEN
    source: AWS_SESSION_TOKEN
  - id: reference
    source: reference
  - id: bcftools_cmd_list
    source: generate_shards/bcftools_cmd
  - id: shard
    source: generate_shards/shard_interval
  - id: dbSNP
    source: dbSNP
  - id: call_conf
    source: call_conf
  - id: emit_conf
    source: emit_conf
  - id: genotype_model
    source: genotype_model
  scatter:
  - bcftools_cmd_list
  - shard
  scatterMethod: dotproduct
  run: ../tools/sentieon_gvcftyper.cwl
  out: [output_vcf]
- id: sentieon_gvcftyper_merge
  label: Sentieon_GVCFtyper_Merge
  in:
  - id: sentieon_license
    source: sentieon_license
  - id: reference
    source: reference
  - id: advanced_driver_options
    default: --passthru
  - id: input_gvcf_files
    source:
    - sentieon_gvcftyper_distributed/output_vcf
  - id: advanced_algo_options
    default: --merge
  - id: output_file_name
    source: output_file_name
    default: joint_final.vcf.gz
  run: ../tools/sentieon_gvcftyper.cwl
  out:
  - id: output_vcf
