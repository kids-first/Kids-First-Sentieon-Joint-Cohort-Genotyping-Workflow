cwlVersion: v1.2
class: Workflow
id: joint_call_upfront_shard
label: Joint Cohort Calling Workflow Beta

requirements:
- class: ScatterFeatureRequirement
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
inputs:
  reference: { type: File, doc: "Reference fasta with associated fai index", secondaryFiles: ['.fai'], "sbg:fileTypes": "FA, FASTA"}
  fai_subset: { type: 'int?', doc: "Number of lines from head of fai to keep", default: 24 }
  # num_shards: { type: 'int?', doc: "Nunber of shards to make" }
  split_by_chr: { type: 'boolean?', doc: "Split by chr instead", default: false }
  input_vcf: { type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi']}
  bcftools_cpu: { type: 'int?', default: 3 }
  gvcf_typer_cpus: { label: GVCF Typer CPUs, type: 'int?', doc: "Num CPUs per gvcf typer job", default: 48 }
  gvcf_typer_mem: { label: GVCF Typer Mem (in GB), type: 'int?', doc: "Amount of ram to use per gvcf typer job (in GB)", default: 48 }
  sentieon_license: { label: Sentieon license, doc: "License server host and port", type: string }
  dbSNP: {type: 'File?', secondaryFiles: ['.tbi'], doc: "dbSNP file to annotate with"}
  call_conf: { label: Call confidence level, type: 'int?' }
  emit_conf: { label: Emit confidence level, type: 'int?' }
  genotype_model: { label: Genotype model, doc: "Genotype model: coalescent or multinomial. While the coalescent mode is theoretically more accurate for smaller cohorts, the multinomial mode is equally accurate with large cohorts and scales better with a very large number of samples.",
    type: ['null', {name: genotype_model, type: enum, symbols: [ "coalescent", "multinomial" ]}], default: multinomial }
  advanced_driver_options: { type: 'string?', default: "--passthru" }
  advanced_algo_options: { type: 'string?', default: "--merge" }
  output_file_prefix: {label: Output file name, doc: "The output VCF file prefix name. Must end with .vcf.gz.", type: 'string?' , default: joint_call }
outputs:
  joint_called_vcf: { type: 'File?', secondaryFiles: ['.tbi'], outputSource: sentieon_gvcftyper_merge/output_vcf }
  joint_called_by_chr_vcf: { type: 'File[]?', secondaryFiles: ['.tbi'], outputSource: sentieon_gvcftyper_distributed/output_vcf }

steps:
  subset_fai:
    run: ../tools/fai_subset.cwl
    in:
      reference_fai:
        source: reference
        valueFrom: $(self.secondaryFiles[0])
      num_lines: fai_subset
    out: [reference_fai_subset, chr_list]
  # generate_shards:
  #   when: $(inputs.num_shards != null)
  #   run: ../tools/shard_fai.cwl
  #   in:
  #     reference_index: subset_fai/reference_fai_subset
  #     num_shards: num_shards
  #   out: [shard_interval, bcftools_padded_scatter]
  # bcftools_shard_vcf:
  #   hints:
  #   - class: sbg:AWSInstanceType
  #     value: c5.12xlarge
  #   when: $(inputs.region_scatter_file != null)
  #   run: ../tools/bcftools_shard_vcf.cwl
  #   in:
  #     input_vcf: input_vcf
  #     region_scatter_file: generate_shards/bcftools_padded_scatter
  #     threads: bcftools_cpu
  #   scatter: [input_vcf]
  #   out: [sharded_vcfs]
  split_vcf_by_chr:
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    when: $(inputs.split_by_chr)
    run: ../tools/split_by_chr.cwl
    in:
      input_vcf: input_vcf
      chr_list: subset_fai/chr_list
      chr_array: make_output_name/out_intvl_list
      threads: bcftools_cpu
      sentieon_license: sentieon_license
    scatter: [input_vcf]
    out: [split_vcfs]
  make_output_name:
    run:
      class: ExpressionTool
      cwlVersion: v1.2
      requirements:
      - class: InlineJavascriptRequirement
      expression: |
        ${
          if (inputs.split_by_chr){
            var out_intvl_list = inputs.chr_list.contents.trim().split("\n");
            var out_name_list = out_intvl_list.map(function (i){
              return inputs.output_file_prefix + "_" + i.replace(/,/g, "-") + ".vcf.gz";
            })
            return {"out_name_list": out_name_list, "out_intvl_list": out_intvl_list};
          } else {
            return {"out_name_list": [inputs.output_file_prefix + ".vcf.gz"], "out_intvl_list": out_intvl_list};
          } 
        }
      inputs:
        split_by_chr: boolean
        output_file_prefix: string
        chr_list: { type: File, loadContents: true }
      outputs:
        out_name_list: 'string[]'
        out_intvl_list: 'string[]'
    in:
      split_by_chr: split_by_chr
      output_file_prefix: output_file_prefix
      chr_list: subset_fai/chr_list
    out: [out_name_list, out_intvl_list]
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
      len_scatter:
        source: [split_by_chr, fai_subset]
        valueFrom: "$(self[0] ? self[1] : self[2].length)"
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
      # shard:
      #   source: generate_shards/shard_interval
      #   valueFrom: $(self[inputs.scatter_index])
      interval:
        source: make_output_name/out_intvl_list
        valueFrom: $(self[inputs.scatter_index])
      dbSNP: dbSNP
      call_conf: call_conf
      emit_conf: emit_conf
      genotype_model: genotype_model
      output_file_name:
        source: make_output_name/out_name_list
        valueFrom: $(self[inputs.scatter_index])
    scatter: [scatter_index]
    scatterMethod: dotproduct
    out: [output_vcf]

  sentieon_gvcftyper_merge:
    when: $(inputs.split_by_chr == null)
    run: ../tools/sentieon_gvcftyper.cwl
    label: Sentieon_GVCFtyper_Merge
    in:
      split_by_chr: split_by_chr
      sentieon_license: sentieon_license
      reference: reference
      advanced_driver_options: advanced_driver_options
      input_gvcf_files: sentieon_gvcftyper_distributed/output_vcf
      advanced_algo_options: advanced_algo_options
      output_file_name:
        source: make_output_name/out_name_list
        valueFrom: $(self[0])
    out: [output_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: sbg:maxNumberOfParallelInstances
  value: 60
