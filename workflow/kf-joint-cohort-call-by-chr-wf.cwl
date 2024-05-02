cwlVersion: v1.2
class: Workflow
id: kf-joint-cohort-call-by-chr-wf
label: Kids First-Senteion Joint Cohort Calling Workflow Beta

requirements:
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement
inputs:
  reference: { type: File, doc: "Reference fasta with associated fai index", secondaryFiles: ['.fai'], "sbg:fileTypes": "FA, FASTA",
    "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3, name: Homo_sapiens_assembly38.fasta, secondaryFiles: [{class: File, path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai}]} }
  fai_subset: { type: 'int?', doc: "Number of lines from head of fai to keep", default: 24 }
  input_vcf: { type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi']}
  bcftools_cpu: { type: 'int?', default: 4 }
  gvcf_typer_cpus: { type: 'int?', doc: "Num CPUs per gvcf typer job", default: 48 }
  gvcf_typer_mem: { type: 'int?', doc: "Amount of ram to use per gvcf typer job (in GB)", default: 48 }
  sentieon_license: { type: 'string?', doc: "License server host and port", default: "10.5.64.221:8990" }
  dbSNP: { type: 'File?', secondaryFiles: ['.tbi'], doc: "dbSNP file to annotate with" }
  call_conf: { type: 'int?', doc: "Call confidence level (default: 30)", default: 30 }
  emit_conf: { type: 'int?', doc: "Emit confidence level (default: 30)", default: 30 }
  genotype_model: { type: ['null', {name: genotype_model, type: enum, symbols: [ "coalescent", "multinomial" ]}], default: multinomial,
    doc: "While the coalescent mode is theoretically more accurate for smaller cohorts, the multinomial mode is equally accurate with large cohorts and scales better with a very large number of samples." }
  output_file_prefix: { type: 'string?' , default: "joint_call" }
outputs:
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

  split_vcf_by_chr:
    hints:
    - class: sbg:AWSInstanceType
      value: c5.12xlarge
    run: ../tools/bcftools_split_by_chr.cwl
    in:
      input_vcf: input_vcf
      chr_list: subset_fai/chr_list
      chr_array: make_output_name/out_intvl_list
      threads: bcftools_cpu
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
          var out_intvl_list = inputs.chr_list.contents.trim().split("\n");
          var out_name_list = out_intvl_list.map(function (i){
            return inputs.output_file_prefix + "_" + i.replace(/,/g, "-") + ".vcf.gz";
          })
          return {"out_name_list": out_name_list, "out_intvl_list": out_intvl_list};
        }
      inputs:
        output_file_prefix: string
        chr_list: { type: File, loadContents: true }
      outputs:
        out_name_list: 'string[]'
        out_intvl_list: 'string[]'
    in:
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

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: sbg:maxNumberOfParallelInstances
  value: 60
