cwlVersion: v1.2
class: CommandLineTool
id: sentieon-varcal-snps
label: Sentieon_VarCal_SNPs
doc: |-
  The VarCal algorithm calculates the Variant Quality Score Recalibration (VQSR). VQSR assigns a well-calibrated probability score to individual variant calls, to enable more accurate control in determining the most likely variants.

requirements:
- class: ShellCommandRequirement
- class: ResourceRequirement
  coresMin: $(inputs.threads)
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
    sentieon driver --algo VarCal --tranches_file snp.tranches --var_type SNP
    --resource $(inputs.hapmap_resource_vcf.path) --resource_param hapmap,known=false,training=true,truth=true,prior=15
    --resource $(inputs.omni_resource_vcf.path) --resource_param omni,known=false,training=true,truth=true,prior=12
    --resource $(inputs.one_thousand_genomes_resource_vcf.path) --resource_param 1000G,known=false,training=true,truth=false,prior=10
    --resource $(inputs.dbsnp_resource_vcf.path) --resource_param dbsnp,known=true,training=false,truth=false,prior=7

inputs:
  sentieon_license: { type: string, doc: "Sentieon license server and port, in format 0.0.0.0:0000 " }
  input_vcf: { type: File, secondaryFiles: ['.tbi'], inputBinding: { position: 1, prefix: "-v"} }
  annotation: { type: 'File[]?', doc: "determine annotation that will be used during the recalibration. You can include multiple annotations in the optimization by repeating the --annotation ANNOTATION option. You can use all annotations present in the original variant call file",
    inputBinding: { position: 1, prefix: "--annotation", separate: false} }
  hapmap_resource_vcf: { type: File, secondaryFiles: [''.tbi'] }
  omni_resource_vcf: { type: File, secondaryFiles: [''.tbi'] }
  one_thousand_genomes_resource_vcf: { type: File, secondaryFiles: [''.tbi'] }
  dbsnp_resource_vcf: { type: File, secondaryFiles: [''.tbi'] }
  max_gaussians: { type: 'int?', doc: "determines the maximum number of Gaussians that will be used for the positive recalibration model",
    default: 6, inputBinding: { position: 1, prefix: "--max_gaussians"} }
  tranche: { type: 'int?', doc: "normalized quality threshold for each tranche; the TRANCH_THRESHOLD number is a number between 0 and 100. Multiple instances of the option are allowed that will create as many tranches as there are thresholds"
    default: [100.0,99.95,99.9,99.8,99.6,99.5,99.4,99.3,99.0,98.0,97.0,90.0], inputBinding: { position: 0, prefix: "--tranche", separate: false}}
  srand: { type: 'int?', doc: "determines the seed to use in the random number generation. You can set RANDOM_SEED to 0 and the software will use the random seed from your computer. In order to generate a deterministic result, you should use a non-zero RANDOM_SEED and set the NUMBER_THREADS to 1",
    default: 42, inputBinding: {position: 1, , prefix: "--srand"} }

outputs:
  recal: { type: File, outputBinding: { glob: "*recal*"}}

