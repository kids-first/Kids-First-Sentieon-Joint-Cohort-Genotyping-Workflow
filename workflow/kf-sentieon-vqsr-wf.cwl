cwlVersion: v1.2
class: Workflow
id: kf-sentieon-vqsr-wf
label: Kids First-Sentieon VQSR Equivalent Workflow

doc: |
  # Kids First-Sentieon VQSR Equivalent Workflow

  This workflow generally follows the guidelines outlined in the [Variant Quality Score Recalibration (VQSR)](https://gatk.broadinstitute.org/hc/en-us/articles/360035531612-Variant-Quality-Score-Recalibration-VQSR) and [Which training sets arguments should I use for running VQSR?](https://gatk.broadinstitute.org/hc/en-us/articles/4402736812443-Which-training-sets-arguments-should-I-use-for-running-VQSR).
  Many find VQSR useful for evaluating the quality of calls made.
  We use Sentieon tools to more efficiently implement an equivalent of the VQSR portion of our [Kids First DRC Joint Genotyping Workflow](https://github.com/kids-first/kf-jointgenotyping-workflow/tree/master) used in trio calling.
  It is to be run after the [Kids First-Sentieon Joint Cohort Calling](../README.md) Workflow.

  ## Inputs
  ### Required:
   - `reference`: Indexed FASTA file reference. Should be the same one used to create the input gVCFs
   - `input_vcfs`: Array of by-chromosome joint called VCFs. Workflow will merge before applying VQSR
   - `sentieon_license`: Sentieon license server host and port in format `0.0.0.0:0000`. Is set by default by the workflow, but can be changed if circumstances require it
   - `dbsnp_vcf`: Homo_sapiens_assembly38.dbsnp138.vcf # pulled by workflow by default
   - `hapmap_resource_vcf`: hapmap_3.3.hg38.vcf.gz
   - `mills_resource_vcf`: Mills_and_1000G_gold_standard.indels.hg38.vcf.gz
   - `omni_resource_vcf`: 1000G_omni2.5.hg38.vcf.gz
   - `one_thousand_genomes_resource_vcf`: 1000G_phase1.snps.high_confidence.hg38.vcf.gz
   - `output_basename`: String to prepend to output
  ### Optional
   - `bcftools_cpu`: Default `8`. Number of cores to be used ot merge VCFs
   - `output_type` Default `z`. Format of merged variants file
   - `varcal_threads`: Default `1`. Sentieon documentation states for VarCal to be deterministic, it must be set 1, but will be much slower
   `varcal_ram`: Default `16`. RAM in GB to providew to VarCal jobs. May need to increase depending on size of input
   - `srand`: Default `42`. Determines the seed to use in the random number generation. You can set RANDOM_SEED to 0 and the software will use the random seed from your computer. In order to generate a deterministic result, you should use a non-zero RANDOM_SEED
   - `snp_max_gaussians`: Default `6`. Integer value for max gaussians in SNP VariantRecalibration. If a dataset gives fewer variants
        than the expected scale, the number of Gaussians for training should be turned down. Lowering the max-Gaussians forces the program
        to group variants into a smaller number of clusters, which results in more variants per cluster
   - `snp_tranche`: Default `[ 100.0, 99.95, 99.9, 99.8, 99.6, 99.5, 99.4, 99.3, 99.0, 98.0, 97.0, 90.0 ]`. Normalized quality threshold for each tranche; the TRANCH_THRESHOLD number is a number between 0 and 100
   - `snp_annotation`: Default: `[ 'QD', 'MQRankSum', 'ReadPosRankSum', 'FS', 'MQ', 'SOR', 'DP' ]`. determine annotation that will be used during the indel recalibration
   - `indel_max_gaussians`: Default `4`. Integer value for max gaussians in INDEL VariantRecalibration. If a dataset gives fewer
        variants than the expected scale, the number of Gaussians for training should be turned down. Lowering the max-Gaussians forces
        the program to group variants into a smaller number of clusters, which results in more variants per cluster.
   - `indel_tranche`: Default `[ 100.0, 99.95, 99.9, 99.5, 99.0, 97.0, 96.0, 95.0, 94.0, 93.5, 93.0, 92.0, 91.0, 90.0 ]`. Normalized quality threshold for each tranche; the TRANCH_THRESHOLD number is a number between 0 and 100
   - `indel_annotation`: Default: `[ 'FS', 'ReadPosRankSum', 'MQRankSum', 'QD', 'SOR', 'DP' ]`. determine annotation that will be used during indel recalibration

  ## Outputs:
   - `vqsr_vcf`: Merged VQSR VCF with tranch filters

  ## Run tips
   - The default 1TB storage per instance might be enough for up to a 1500 sample cohort size. To be safe, set this to at least 2TB if not more for larger cohorts in the task, documentation on this here: https://docs.sevenbridges.com/docs/set-execution-hints-at-task-level. An example would be to use the following:
     - Instance type: `c5.2xlarge` # Must meet requirements of min threads set for any tool
     - EBS storage: `2048` up to `4096`
     - Number of parallel instances: `2`. Most users have an `80` max limit per account

requirements:
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
inputs:
  reference: {type: File, doc: "Reference fasta with associated fai index", secondaryFiles: ['.fai'], "sbg:fileTypes": "FA, FASTA",
    "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3, name: Homo_sapiens_assembly38.fasta, secondaryFiles: [{class: File,
          path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai}]}}
  input_vcfs: {type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi']}
  output_basename: string
  bcftools_cpu: {type: 'int?', default: 8}
  output_type: {type: ['null', {type: enum, name: output_type, symbols: ["b", "u", "v", "z"]}], default: "z", doc: "b: compressed
      BCF, u: uncompressed BCF, z: compressed VCF, v: uncompressed VCF [v]"}
  sentieon_license: {type: 'string?', doc: "License server host and port", default: "10.5.64.221:8990"}
  varcal_threads: {type: 'int?', doc: "Number of threads to set for VarCal. MUST BE 1 IF YOU WANT IT TO BE DETERMINISTIC", default: 8}
  varcal_ram: {type: 'int?', default: 16, doc: "RAM in GB to providew to VarCal jobs. May need to increase depending on size of input"}
  srand: {type: 'int?', default: 42, doc: "Determines the seed to use in the random number generation. You can set RANDOM_SEED to
      0 and the software will use the random seed from your computer. In order to generate a deterministic result, you should use
      a non-zero RANDOM_SEED"}
  axiomPoly_resource_vcf: {type: File, secondaryFiles: [{pattern: '.tbi', required: true}], doc: 'Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz',
    "sbg:suggestedValue": {class: File, path: 60639016357c3a53540ca7c7, name: Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz,
      secondaryFiles: [{class: File, path: 6063901d357c3a53540ca81b, name: Axiom_Exome_Plus.genotypes.all_populations.poly.hg38.vcf.gz.tbi}]}}
  dbsnp_vcf: {type: File, secondaryFiles: [{pattern: '.idx', required: true}], doc: 'Homo_sapiens_assembly38.dbsnp138.vcf', "sbg:suggestedValue": {
      class: File, path: 6063901f357c3a53540ca84b, name: Homo_sapiens_assembly38.dbsnp138.vcf, secondaryFiles: [{class: File, path: 6063901e357c3a53540ca834,
          name: Homo_sapiens_assembly38.dbsnp138.vcf.idx}]}}
  hapmap_resource_vcf: {type: File, secondaryFiles: [{pattern: '.tbi', required: true}], doc: 'Hapmap genotype SNP input vcf', "sbg:suggestedValue": {
      class: File, path: 60639016357c3a53540ca7be, name: hapmap_3.3.hg38.vcf.gz, secondaryFiles: [{class: File, path: 60639016357c3a53540ca7c5,
          name: hapmap_3.3.hg38.vcf.gz.tbi}]}}
  mills_resource_vcf: {type: File, secondaryFiles: [{pattern: '.tbi', required: true}], doc: 'Mills_and_1000G_gold_standard.indels.hg38.vcf.gz',
    "sbg:suggestedValue": {class: File, path: 6063901a357c3a53540ca7f3, name: Mills_and_1000G_gold_standard.indels.hg38.vcf.gz, secondaryFiles: [
        {class: File, path: 6063901c357c3a53540ca806, name: Mills_and_1000G_gold_standard.indels.hg38.vcf.gz.tbi}]}}
  omni_resource_vcf: {type: File, secondaryFiles: [{pattern: '.tbi', required: true}], doc: '1000G_omni2.5.hg38.vcf.gz', "sbg:suggestedValue": {
      class: File, path: 6063901e357c3a53540ca835, name: 1000G_omni2.5.hg38.vcf.gz, secondaryFiles: [{class: File, path: 60639016357c3a53540ca7b1,
          name: 1000G_omni2.5.hg38.vcf.gz.tbi}]}}
  one_thousand_genomes_resource_vcf: {type: File, secondaryFiles: [{pattern: '.tbi', required: true}], doc: '1000G_phase1.snps.high_confidence.hg38.vcf.gz,
      high confidence snps', "sbg:suggestedValue": {class: File, path: 6063901c357c3a53540ca80f, name: 1000G_phase1.snps.high_confidence.hg38.vcf.gz,
      secondaryFiles: [{class: File, path: 6063901e357c3a53540ca845, name: 1000G_phase1.snps.high_confidence.hg38.vcf.gz.tbi}]}}
  snp_max_gaussians: {type: 'int?', default: 6, doc: "Integer value for max gaussians in SNP VariantRecalibration. If a dataset gives
      fewer variants than the expected scale, the number of Gaussians for training should be turned down. Lowering the max-Gaussians
      forces the program to group variants into a smaller number of clusters, which results in more variants per cluster."}
  snp_tranche: {type: ['null', {type: array, items: float}], doc: "normalized quality threshold for each tranche; the TRANCH_THRESHOLD
      number is a number between 0 and 100. Multiple instances of the option are allowed that will create as many tranches as there
      are thresholds", default: [100.0, 99.95, 99.9, 99.8, 99.6, 99.5, 99.4, 99.3, 99.0, 98.0, 97.0, 90.0]}
  snp_annotation: {type: ['null', {type: array, items: string}], doc: "determine annotation that will be used during the recalibration",
    default: ['QD', 'MQRankSum', 'ReadPosRankSum', 'FS', 'MQ', 'SOR', 'DP']}
  indel_max_gaussians: {type: 'int?', default: 4, doc: "Integer value for max gaussians in INDEL VariantRecalibration. If a dataset
      gives fewer variants than the expected scale, the number of Gaussians for training should be turned down. Lowering the max-Gaussians
      forces the program to group variants into a smaller number of clusters, which results in more variants per cluster."}
  indel_tranche: {type: ['null', {type: array, items: float}], doc: "normalized quality threshold for each tranche; the TRANCH_THRESHOLD
      number is a number between 0 and 100. Multiple instances of the option are allowed that will create as many tranches as there
      are thresholds", default: [100.0, 99.95, 99.9, 99.5, 99.0, 97.0, 96.0, 95.0, 94.0, 93.5, 93.0, 92.0, 91.0, 90.0]}
  indel_annotation: {type: ['null', {type: array, items: string}], doc: "determine annotation that will be used during the recalibration",
    default: ['FS', 'ReadPosRankSum', 'MQRankSum', 'QD', 'SOR', 'DP']}


outputs:
  vqsr_vcf: {type: File, outputSource: Sentieon_ApplyVarCal/vqsr_vcf}

steps:
  bcftools_concat:
    run: ../tools/bcftools_concat.cwl
    in:
      threads: bcftools_cpu
      output:
        source: output_basename
        valueFrom: $(self).merged.vcf.gz
      output_type: output_type
      input_vcfs: input_vcfs
    out: [merged_vcf]
  Sentieon_VarCal_SNPs:
    run: ../tools/sentieon_varcal_snps.cwl
    doc: 'Create recalibration model for snps using GATK VariantRecalibrator, tranch values, and known site VCFs'
    in:
      sentieon_license: sentieon_license
      threads: varcal_threads
      ram: varcal_ram
      reference: reference
      input_vcf: bcftools_concat/merged_vcf
      dbsnp_resource_vcf: dbsnp_vcf
      hapmap_resource_vcf: hapmap_resource_vcf
      omni_resource_vcf: omni_resource_vcf
      one_thousand_genomes_resource_vcf: one_thousand_genomes_resource_vcf
      max_gaussians: snp_max_gaussians
      srand: srand
      tranche: snp_tranche
      annotation: snp_annotation
    out: [recal, tranches]
  Sentieon_VarCal_INDELs:
    run: ../tools/sentieon_varcal_indels.cwl
    in:
      sentieon_license: sentieon_license
      threads: varcal_threads
      ram: varcal_ram
      reference: reference
      input_vcf: bcftools_concat/merged_vcf
      axiomPoly_resource_vcf: axiomPoly_resource_vcf
      dbsnp_resource_vcf: dbsnp_vcf
      mills_resource_vcf: mills_resource_vcf
      max_gaussians: indel_max_gaussians
      srand: srand
      tranche: indel_tranche
      annotation: indel_annotation
    out: [recal, tranches]
  Sentieon_ApplyVarCal:
    run: ../tools/sentieon_apply_varcal.cwl
    in:
      sentieon_license: sentieon_license
      reference: reference
      indels_recalibration: Sentieon_VarCal_INDELs/recal
      indels_tranches: Sentieon_VarCal_INDELs/tranches
      input_vcf: bcftools_concat/merged_vcf
      snps_recalibration: Sentieon_VarCal_SNPs/recal
      snps_tranches: Sentieon_VarCal_SNPs/tranches
      output_basename: output_basename
    out: [vqsr_vcf]

$namespaces:
  sbg: https://sevenbridges.com
hints:
- class: sbg:maxNumberOfParallelInstances
  value: 2
sbg:license: Apache License 2.0
sbg:publisher: KFDRC
