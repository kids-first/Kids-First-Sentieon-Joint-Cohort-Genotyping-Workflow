cwlVersion: v1.2
class: CommandLineTool
label: Sentieon_GVCFtyper_No_DL
doc: |-
  The Sentieon **GVCFtyper** binary performs joint genotyping using One or more GVCFs.

  ### Notes:
  * Set `--genotype_model=coalescent --emit_conf=10 --call_conf=10` to match GATK 3.7, 3.8, 4.0.
  * Set `--genotype_model=multinomial --emit_conf=30 --call_conf=30` to match GATK 4.1. (default)

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(inputs.cpu_per_job)
  ramMin: $(inputs.mem_per_job * 1000)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.02_cavatica
- class: EnvVarRequirement
  envDef:
  - envName: SENTIEON_LICENSE
    envValue: $(inputs.sentieon_license)
  - envName: VCFCACHE_BLOCKSIZE
    envValue: "4096"
- class: InlineJavascriptRequirement

$namespaces:
  sbg: https://sevenbridges.com

inputs:
- id: sentieon_license
  label: Sentieon license
  doc: License server host and port
  type: string
- id: input_gvcf_files
  label: Input GVCFs
  type: File[]
  secondaryFiles:
  - pattern: .tbi
    required: false
  - pattern: .idx
    required: false
  inputBinding:
    position: 300
    shellQuote: false
  sbg:fileTypes: VCF, VCF.GZ, GVCF, GVCF.GZ
- id: reference
  label: Reference
  doc: Reference fasta file with associated indexes
  type: File
  secondaryFiles:
  - pattern: .fai
    required: true
  inputBinding:
    prefix: -r
    position: 11
    shellQuote: true
  sbg:fileTypes: FA, FASTA
- id: shard
  type: File?
  loadContents: true
  inputBinding:
    position: 12
    valueFrom: |
      --shard $(self.contents)
    shellQuote: false
- id: advanced_driver_options
  label: Advanced driver options
  doc: The options for driver.
  type: string?
  inputBinding:
    position: 13
    shellQuote: false
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
  inputBinding:
    prefix: -d
    position: 101
    shellQuote: true
- id: emit_mode
  label: Emit mode
  doc: 'Emit mode: variant, confident or all (default: variant)'
  type:
  - 'null'
  - name: emit_mode
    type: enum
    symbols:
    - variant
    - confident
    - all
  inputBinding:
    prefix: --emit_mode
    position: 101
    shellQuote: true
  sbg:toolDefaultValue: variant
- id: call_conf
  label: Call confidence level
  doc: 'Call confidence level (default: 30)'
  type: int?
  default: 30
  inputBinding:
    prefix: --call_conf
    position: 101
    shellQuote: true
- id: emit_conf
  label: Emit confidence level
  doc: 'Emit confidence level (default: 30)'
  type: int?
  default: 30
  inputBinding:
    prefix: --emit_conf
    position: 101
    shellQuote: true
- id: genotype_model
  label: Genotype model
  doc: |-
    Genotype model: coalescent or multinomial. 
    While the coalescent mode is theoretically more accuracy for smaller cohorts, the multinomial mode is equally accurate with large cohorts and scales better with a very large numbers of samples.
  type:
  - 'null'
  - name: genotype_model
    type: enum
    symbols:
    - coalescent
    - multinomial
  default: multinomial
  inputBinding:
    prefix: --genotype_model
    position: 101
    shellQuote: true
- id: max_alt_alleles
  label: Maximum alt alleles
  doc: 'Maximum number of alternate alleles (default: 100)'
  type: int?
  inputBinding:
    prefix: --max_alt_alleles
    position: 101
    shellQuote: true
  sbg:toolDefaultValue: '100'
- id: advanced_algo_options
  label: Advanced algo options
  doc: The options for --algo GVCFtyper.
  type: string?
  inputBinding:
    position: 102
    shellQuote: false
- id: output_file_name
  label: Output file name
  doc: The output VCF file name. Must end with ".vcf.gz".
  type: string?
- id: cpu_per_job
  label: CPU per job
  doc: CPU per job
  type: int?
  default: 32
- id: mem_per_job
  label: Memory per job
  doc: Memory per job[GB]
  type: int?
  default: 32

outputs:
- id: output_vcf
  type: File
  secondaryFiles:
  - pattern: .tbi
    required: true
  outputBinding:
    glob: '*.vcf.gz'
  sbg:fileTypes: VCF.GZ

arguments:
- position: 10
  valueFrom: sentieon driver --traverse_param 10000/200
  shellQuote: false
- prefix: '--algo'
  position: 100
  valueFrom: GVCFtyper
  shellQuote: false
- position: 200
  valueFrom: |-
    ${
        if (inputs.output_file_name)
            return inputs.output_file_name
        else
            return "output.vcf.gz"
    }
  shellQuote: false


