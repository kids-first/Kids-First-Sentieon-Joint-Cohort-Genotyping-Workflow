cwlVersion: v1.2
class: CommandLineTool
id: sentieon-apply-varcal
label: Sentieon_ApplyVarCal
doc: |-
  The ApplyVarCal algorithm combines the output information from the VQSR with the original variant information

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(Math.max(inputs.threads, 8))
  ramMin: $(inputs.ram * 1000)
- class: DockerRequirement
  dockerPull: pgc-images.sbgenomics.com/hdchen/sentieon:202308.02_cavatica
- class: EnvVarRequirement
  envDef:
  - envName: SENTIEON_LICENSE
    envValue: $(inputs.sentieon_license)

- class: InlineJavascriptRequirement

arguments:
- position: 0
  shellQuote: false
  valueFrom: >-
    sentieon driver
- position: 2
  shellQuote: false
  valueFrom: >-
    --algo ApplyVarCal
    --vqsr_model var_type=SNP,recal=$(inputs.snps_recalibration.path),tranches_file=$(inputs.snps_tranches.path),sensitivity=$(inputs.snp_sensitivity)
    --vqsr_model var_type=INDEL,recal=$(inputs.indels_recalibration.path),tranches_file=$(inputs.indels_tranches.path),sensitivity=$(inputs.indel_sensitivity)
- position: 3
  shellQuote: false
  valueFrom: >-
    $(inputs.output_basename).VQSR.vcf.gz
inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000 " }
  threads: { type: 'int?', doc: "number of computing threads that will be used by the software to run parallel processes. See srand doc for deterministic behavior",
    default: 8, inputBinding: { position: 1, prefix: "-t" } }
  ram: { type: 'int?', doc: "RAM in GB to make available to this task", default: 16 }
  reference: { type: File, secondaryFiles: ['.fai'],  doc: "location of the reference FASTA file",
    inputBinding: { position: 1, prefix: "--reference"} }
  input_vcf: { type: File, secondaryFiles: ['.tbi'], inputBinding: { position: 2, prefix: "-v"} }
  snps_recalibration: { type: File, secondaryFiles: ['.idx'], doc: "location of the SNP VCF file output from the VarCal algorithm" }
  snps_tranches: { type: File, doc: "location of the SNP tranches file output from the VarCal algorithm" }
  snp_sensitivity: { type: 'float?', default: 99.7, doc: "determine the SNP sensitivity to the available truth sites; only tranches with threshold larger than the sensitivity will be included in the recalibration"}
  indels_recalibration: { type: File, secondaryFiles: ['.idx'], doc: "location of the INDEL VCF file output from the VarCal algorithm" }
  indels_tranches: { type: File, doc: "location of the INDEL tranches file output from the VarCal algorithm" }
  indel_sensitivity: { type: 'float?', default: 99.7, doc: "determine the INDEL sensitivity to the available truth sites; only tranches with threshold larger than the sensitivity will be included in the recalibration"}
  output_basename: { type: 'string?', default: "snps"}

outputs:
  vqsr_vcf: { type: File, outputBinding: { glob: "*VQSR.vcf.gz"}, secondaryFiles: ['.tbi'] }
