cwlVersion: v1.2
class: CommandLineTool
id: sentieon-varcal-indels
label: Sentieon_VarCal_INDELs
doc: |-
  The VarCal algorithm calculates the Variant Quality Score Recalibration (VQSR). VQSR assigns a well-calibrated probability score to individual variant calls, to enable more accurate control in determining the most likely variants.

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
    --algo VarCal --tranches_file $(inputs.output_basename).indels.tranches --var_type INDEL
    --resource $(inputs.mills_resource_vcf.path) --resource_param mills,known=false,training=true,truth=true,prior=12
    --resource $(inputs.axiomPoly_resource_vcf.path) --resource_param axiomPoly,known=false,training=true,truth=false,prior=10
    --resource $(inputs.dbsnp_resource_vcf.path) --resource_param known=true,training=false,truth=false,prior=2
- position: 3
  shellQuote: false
  valueFrom: >-
    $(inputs.output_basename).recal
inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000 " }
  ram: { type: 'int?', doc: "RAM in GB to make available to this task", default: 16 }
  threads: { type: 'int?', doc: "number of computing threads that will be used by the software to run parallel processes. See srand doc for deterministic behavior",
    default: 1, inputBinding: { position: 1, prefix: "-t" } }
  reference: { type: File, secondaryFiles: ['.fai'],  doc: "location of the reference FASTA file",
    inputBinding: { position: 1, prefix: "--reference"} }
  input_vcf: { type: File, secondaryFiles: ['.tbi'], inputBinding: { position: 2, prefix: "-v"} }
  mills_resource_vcf: { type: File, secondaryFiles: ['.tbi'] }
  axiomPoly_resource_vcf: { type: File, secondaryFiles: ['.tbi'] }
  dbsnp_resource_vcf: { type: File, secondaryFiles: ['.idx'] }
  max_gaussians: { type: 'int?', doc: "determines the maximum number of Gaussians that will be used for the positive recalibration model",
    default: 4, inputBinding: { position: 2, prefix: "--max_gaussians"} }
  tranche: { type: ['null', { type: array, items: float,  inputBinding: { prefix: "--tranche", separate: true }}], doc: "normalized quality threshold for each tranche; the TRANCH_THRESHOLD number is a number between 0 and 100. Multiple instances of the option are allowed that will create as many tranches as there are thresholds",
    default: [ 100.0, 99.95, 99.9, 99.5, 99.0, 97.0, 96.0, 95.0, 94.0, 93.5, 93.0, 92.0, 91.0, 90.0 ], inputBinding: { position: 2 } }
  annotation: { type: ['null', {type: array, items: string, inputBinding: { prefix: "--annotation", separate: true }}], doc: "determine annotation that will be used during the recalibration",
    default: [ 'FS', 'ReadPosRankSum', 'MQRankSum', 'QD', 'SOR', 'DP' ], inputBinding: { position: 2 } }
  srand: { type: 'int?', doc: "Determines the seed to use in the random number generation. You can set RANDOM_SEED to 0 and the software will use the random seed from your computer. In order to generate a deterministic result, you should use a non-zero RANDOM_SEED and set the NUMBER_THREADS to 1",
    default: 42, inputBinding: {position: 2, prefix: "--srand"} }
  output_basename: { type: 'string?', default: "indels"}

outputs:
  recal: { type: File, outputBinding: { glob: "*recal"}, secondaryFiles: ['.idx'] }
  tranches: { type: File, outputBinding: { glob: "*.indels.tranches" } }
