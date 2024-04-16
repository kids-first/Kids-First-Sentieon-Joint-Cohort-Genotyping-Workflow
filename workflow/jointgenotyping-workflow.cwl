cwlVersion: v1.2
class: Workflow
label: Sentieon Distributed Joint Genotyping Workflow

requirements:
- class: ScatterFeatureRequirement
- class: InlineJavascriptRequirement
- class: StepInputExpressionRequirement

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: 'sbg:maxNumberOfParallelInstances'
  value: $(inputs.maxNumberOfParallelInstances)

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
- id: input_gvcfs_list
  label: Input GVCFs
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
- id: size_of_chunks
  label: The size of each chunk (MB).
  type: int?
  sbg:exposed: true
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
  sbg:exposed: true
- id: maxNumberOfParallelInstances
  type: int?
  default: 16
  sbg:exposed: true

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
- id: generate_shards
  label: generate_shards
  in:
  - id: reference
    source: reference
  - id: size_of_chunks
    source: size_of_chunks
  run: ../tools/generate_shards.cwl
  out:
  - id: output
- id: sentieon_gvcftyper_distributed 
  label: Sentieon_GVCFtyper_Distributed 
  in:
  - id: sentieon_license
    source: sentieon_license
  - id: AWS_ACCESS_KEY_ID
    source: AWS_ACCESS_KEY_ID
  - id: AWS_SECRET_ACCESS_KEY
    source: AWS_SECRET_ACCESS_KEY
  - id: reference
    source: reference
  - id: advanced_driver_options
    source: generate_shards/output
  - id: input_gvcfs_list
    source: input_gvcfs_list
  - id: dbSNP
    source: dbSNP
  - id: call_conf
    source: call_conf
  - id: emit_conf
    source: emit_conf
  - id: genotype_model
    source: genotype_model
  scatter:
  - advanced_driver_options
  scatterMethod: dotproduct
  run: ../tools/sentieon_gvcftyper.cwl
  hints:
  - class: 'sbg:AWSInstanceType'
    value: c5.9xlarge
  out:
  - id: output_vcf
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
  - id: cpu_per_job
    default: 2
  run: ../tools/sentieon_gvcftyper.cwl
  out:
  - id: output_vcf
