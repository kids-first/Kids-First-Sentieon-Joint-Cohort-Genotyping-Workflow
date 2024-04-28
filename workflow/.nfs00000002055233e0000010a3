cwlVersion: v1.2
class: Workflow
label: Sentieon Distributed Joint Genotyping Workflow by Chromosome

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
  sbg:fileTypes: FA, FASTA
- id: shard_list
  type: File
  doc: The list of shards. Comma-separated like this "chr21,chr22"
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
- id: gvcf_typer_cpus
  label: GVCF Typer CPUs
  type: 'int?'
  doc: Num CPUs per gvcf typer job
  default: 32
- id: gvcf_typer_mem
  label: GVCF Typer Mem (in GB)
  type: 'int?'
  doc: Amount of ram to use per gvcf typer job (in GB)
  default: 32
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
- id: aws_creds_export
  type: File?
  doc: "File with AWS credentials to source instead of string args"
- id: max_downloads
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
- id: output_file_name_prefix
  type: string
  label: The prefix of output file names

outputs:
- id: output_vcf
  type: File[]
  secondaryFiles:
  - pattern: .tbi
    required: true
  outputSource:
  - sentieon_gvcftyper_distributed/output_vcf
  sbg:fileTypes: VCF.GZ

steps:
- id: opt_name_scatter
  in: 
  - id: output_file_name_prefix
    source: output_file_name_prefix
  - id: shard_list
    source: shard_list
  out:
  - id: opt_name_list
  run:
    class: ExpressionTool
    inputs:
    - id: output_file_name_prefix
      type: string
    - id: shard_list
      type: File
    outputs:
    - id: opt_name_list
      type: string[]
    expression: |
      ${
          var opt_name_list = inputs.shard_list.contents.trim().split("\n");
          opt_name_list = opt_name_list.map(function (i){
            return inputs.output_file_name_prefix + i.replace(",", "-") + ".vcf.gz";
          })
        return {"opt_name_list": opt_name_list};
      }
- id: generate_shards
  in:
  - id: shard_list
    source: shard_list
  - id: input_gvcf_list
    source: input_gvcf_list
  run: ../tools/generate_shards.cwl
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
  - id: cpu_per_job
    source: gvcf_typer_cpus
  - id: mem_per_job
    source: gvcf_typer_mem
  - id: AWS_ACCESS_KEY_ID
    source: AWS_ACCESS_KEY_ID
  - id: AWS_SECRET_ACCESS_KEY
    source: AWS_SECRET_ACCESS_KEY
  - id: AWS_SESSION_TOKEN
    source: AWS_SESSION_TOKEN
  - id: aws_creds_export
    source: aws_creds_export
  - id: reference
    source: reference
  - id: max_downloads
    source: max_downloads
  - id: bcftools_cmd_list
    source: generate_shards/bcftools_cmd
  - id: interval
    source: generate_shards/shard_interval
  - id: dbSNP
    source: dbSNP
  - id: call_conf
    source: call_conf
  - id: emit_conf
    source: emit_conf
  - id: genotype_model
    source: genotype_model
  - id: output_file_name
    source: opt_name_scatter/opt_name_list
  scatter:
  - bcftools_cmd_list
  - interval
  - output_file_name
  scatterMethod: dotproduct
  run: ../tools/sentieon_gvcftyper.cwl
  out: [output_vcf]
