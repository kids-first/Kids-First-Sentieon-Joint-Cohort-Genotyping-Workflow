cwlVersion: v1.2
class: Workflow
id: kf-joint-cohort-call-by-chr-wf
label: Kids First-Sentieon Joint Cohort Calling Workflow Beta

doc: |
  # [Kids First-Sentieon Joint Cohort Calling Workflow Beta](../workflow/kf-joint-cohort-call-by-chr-wf.cwl)
  This workflow is takes a set of gVCF files from a desired cohort and an indexed FASTA reference to create a joint-called cohort.
  It will split the input gVCF files, using up to AWS 60 c5.12xlarge instances, and stack 12 gVCF files per instance to split them by chromosome.
  Then, all of the gVCF chromosome fragments are split, one instance per chromosome, to a Sentieon GVCFtyper job.
  If the user supplies a dbSNP vcf at run time, the outputs will also be annotated with `rs_` IDs in the `ID` column of the VCF.

  ![data service logo](https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png)

  ## Limitations
  Two main limitations currently (as of May 2024) exist for running this cohort workflow on CAVATICA:
   - Cohort Size
   - File input size
  Cohort size is simple - **it must be less than ~2200 samples** to run, otherwise the platform will will quit immediately with error:
  ```
  The scheduled job root is too large to be executed. Please contact support@sbgenomics.com for further assistance if needed.
  ```
  AWS instances by default start with 1TB of EBS storage.
  This can be increased to 4TB; if you still run out of space, consider a smaller cohort if possible, limiting sites, or a different platform (sorry!)

  ## Inputs
  ### Required
   - `reference`: Indexed FASTA file reference. Should be the same one used to create the input gVCFs
   - `input_vcf`: Indexed gVCF files to perform cohort calling on. It's recommended that the [GATK Haplotyper caller workflow](https://cavatica.sbgenomics.com/public/apps/cavatica/apps-publisher/kfdrc-gatk-haplotypecaller-workflow) or [Sentieon equivalent](https://cavatica.sbgenomics.com/public/apps/cavatica/apps-publisher/kfdrc_sentieon_gvcf_wf) had been run to generate each of these inputs. If gVCFs were obtained from GMKF, it will meet this recommendation.
   - `sentieon_license`: Sentieon license server host and port in format 0.0.0.0:0000. Is set by default by the workflow, but can be changed if circumstances require it.
  ### Recommended
   - `dbSNP`: Indexed dbSNP file to add common variant annotation if `ID` field

  ### Optional
   - `fai_subset`: Parameter used to set which chromosome are to be used based ion the fasta index file. It's generally recommended to use only chr1-22,X,Y (some would say canonical), therefore this parameter is set to `24` by default, as the typical fasta index leads with the canonical chromosomes first.
   - `bcftools_cpu`: Dictates the amount of stacking to perform for gVCF split steps. By default set to 4, so number of concurrent files per instance is the number of cores in the instance/bcftools_cpu
   - `gvcf_typer_cpus`: Number of cpus each Sentieon GVCFtyper job should attempt to use. Default for workflow is 48. Adjust this if you change the instance type in the Execution Settings at task setup
   - `gvcf_typer_mem`: Amount of RAM in GB each Sentieon GVCFtyper job should attempt to use. Default for workflow is 48, but in practice will likely be less than 30. Adjust this if you change the instance type in the Execution Settings at task setup
   - `call_conf`: Call confidence level (default: 30)
   - `emit_conf`: Emit confidence level (default: 30)
   - `genotype_model`: "coalescent" or  "multinomial", default: multinomial.
      While the coalescent mode is theoretically more accurate for smaller cohorts, the multinomial mode is equally accurate with large cohorts and scales better with a very large number of samples.
   - `output_file_prefix`: Since outputs will be joint calls split by chromosome, a user-defined convenience to prefix each file output with a string of their choice
     Default is "joint_call", so output files would be named "joint_call_chr1.vcf.gz", "joint_call_chr2.vcf.gz", etc.
  ## Outputs
   - `joint_called_by_chr_vcf`: Array of joint-called files split by chromosome
  ## Run tips
   - The default 1TB storage per instance might be enough for up to a 1500 sample cohort size. To be safe, set this to at least 2TB if not more for larger cohorts in the task, documentation on this here: https://docs.sevenbridges.com/docs/set-execution-hints-at-task-level. An example would be to use the following:
     - Instance type: `c5.12xlarge`
     - EBS storage: `2048` m up to `4096`
     - Number of parallel instances: `60`. Most users have an `80` max limit per account
requirements:
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
inputs:
  reference: {type: File, doc: "Reference fasta with associated fai index", secondaryFiles: ['.fai'], "sbg:fileTypes": "FA, FASTA",
    "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3, name: Homo_sapiens_assembly38.fasta, secondaryFiles: [{class: File,
          path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai}]}}
  fai_subset: {type: 'int?', doc: "Number of lines from head of fai to keep", default: 24}
  input_vcf: {type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi']}
  bcftools_cpu: {type: 'int?', default: 4}
  gvcf_typer_cpus: {type: 'int?', doc: "Num CPUs per gvcf typer job", default: 48}
  gvcf_typer_mem: {type: 'int?', doc: "Amount of ram to use per gvcf typer job (in GB)", default: 48}
  sentieon_license: {type: 'string?', doc: "License server host and port", default: "10.5.64.221:8990"}
  dbSNP: {type: 'File?', secondaryFiles: ['.tbi'], doc: "dbSNP file to annotate with"}
  call_conf: {type: 'int?', doc: "Call confidence level (default: 30), set to 10 for coalescent mode", default: 30}
  emit_conf: {type: 'int?', doc: "Emit confidence level (default: 30), set to 10 for coalescent mode", default: 30}
  genotype_model: {type: ['null', {name: genotype_model, type: enum, symbols: ["coalescent", "multinomial"]}], default: multinomial,
    doc: "While the coalescent mode is theoretically more accurate for smaller cohorts, the multinomial mode is equally accurate with
      large cohorts and scales better with a very large number of samples."}
  output_file_prefix: {type: 'string?', default: "joint_call"}
outputs:
  joint_called_by_chr_vcf: {type: 'File[]?', secondaryFiles: ['.tbi'], outputSource: sentieon_gvcftyper_distributed/output_vcf}

steps:
  subset_fai:
    run: ../tools/fai_subset.cwl
    in:
      reference_fai:
        source: reference
        valueFrom: $(self.secondaryFiles[0])
      num_lines: fai_subset
      output_file_prefix: output_file_prefix
    out: [reference_fai_subset, chr_list, chr_array, output_filename_list]

  split_vcf_by_chr:
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    run: ../tools/bcftools_split_by_chr.cwl
    in:
      input_vcf: input_vcf
      chr_list: subset_fai/chr_list
      chr_array: subset_fai/chr_array
      threads: bcftools_cpu
    scatter: [input_vcf]
    out: [split_vcfs]
  get_scatter_index:
    run:
      class: CommandLineTool
      cwlVersion: v1.2
      requirements:
      - class: InlineJavascriptRequirement
      baseCommand: [echo, done]
      inputs:
        len_scatter:
          type: int
      outputs:
        out_array:
          type: int[]
          outputBinding:
            outputEval: |
              $(Array.apply(null, Array(inputs.len_scatter)).map(function(v,i) { return i }))
    in:
      len_scatter: fai_subset
    out: [out_array]
  sentieon_gvcftyper_distributed:
    run: ../tools/sentieon_gvcftyper.cwl
    in:
      scatter_index: get_scatter_index/out_array
      sentieon_license: sentieon_license
      cpu_per_job: gvcf_typer_cpus
      mem_per_job: gvcf_typer_mem
      reference: reference
      input_gvcf_files:
        source: split_vcf_by_chr/split_vcfs
        valueFrom: |
          $(self.map(function(e) { return e[inputs.scatter_index] }))
      interval: subset_fai/chr_array
      dbSNP: dbSNP
      call_conf: call_conf
      emit_conf: emit_conf
      genotype_model: genotype_model
      output_file_name: subset_fai/output_filename_list
    scatter: [interval, output_file_name, scatter_index]
    scatterMethod: dotproduct
    out: [output_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
  - class: sbg:maxNumberOfParallelInstances
    value: 60
"sbg:license": Apache License 2.0
"sbg:publisher": KFDRC
"sbg:links":
  - id: 'https://github.com/kids-first/Kids-First-Sentieon-Joint-Cohort-Genotyping-Workflow/releases/tag/v0.2.0-beta'
    label: github-release
