cwlVersion: v1.2
class: Workflow
id: kf-sentieon-vqsr-wf
label: Kids First-Sentieon VQSR Equivalent Workflow

doc: |
  Post-joint calling, if a user wishes to run VQSR, use this workflow

requirements:
- class: StepInputExpressionRequirement
- class: InlineJavascriptRequirement
- class: MultipleInputFeatureRequirement
inputs:
  reference: {type: File, doc: "Reference fasta with associated fai index", secondaryFiles: ['.fai'], "sbg:fileTypes": "FA, FASTA",
    "sbg:suggestedValue": {class: File, path: 60639014357c3a53540ca7a3, name: Homo_sapiens_assembly38.fasta, secondaryFiles: [{class: File,
          path: 60639016357c3a53540ca7af, name: Homo_sapiens_assembly38.fasta.fai}]}}
  input_vcfs: {type: 'File[]', doc: "VCF files to process", secondaryFiles: ['.tbi']}
  bcftools_cpu: { type: 'int?', default: 16 }
  output_type: { type: ['null', {type: enum, name: output_type, symbols: ["b", "u", "v", "z"] } ], default: "z",
    doc: "b: compressed BCF, u: uncompressed BCF, z: compressed VCF, v: uncompressed VCF [v]" }
  sentieon_license: {type: 'string?', doc: "License server host and port", default: "10.5.64.221:8990"}
  varcal_threads: { type: 'int?', doc: "Number of threads to set for VarCal. MUST BE 1 IF YOU WANT IT TO BE DETERMINISTIC", default: 1 }
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
  snp_max_gaussians: {type: 'int?', doc: "Interger value for max gaussians in SNP VariantRecalibration. If a dataset gives fewer variants
      than the expected scale, the number of Gaussians for training should be turned down. Lowering the max-Gaussians forces the program
      to group variants into a smaller number of clusters, which results in more variants per cluster."}
  indel_max_gaussians: {type: 'int?', doc: "Interger value for max gaussians in INDEL VariantRecalibration. If a dataset gives fewer
      variants than the expected scale, the number of Gaussians for training should be turned down. Lowering the max-Gaussians forces
      the program to group variants into a smaller number of clusters, which results in more variants per cluster."}
  output_basename: string
outputs:
  vqsr_vcf: { type: File, outputSource: Sentieon_ApplyVarCal/vqsr_vcf }

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
      reference: reference
      input_vcf: bcftools_concat/merged_vcf
      dbsnp_resource_vcf: dbsnp_vcf
      hapmap_resource_vcf: hapmap_resource_vcf
      omni_resource_vcf: omni_resource_vcf
      one_thousand_genomes_resource_vcf: one_thousand_genomes_resource_vcf
      max_gaussians: snp_max_gaussians
    out: [recal, tranches]
  Sentieon_VarCal_INDELs:
    run: ../tools/sentieon_varcal_indels.cwl
    in:
      sentieon_license: sentieon_license
      threads: varcal_threads
      reference: reference
      input_vcf: bcftools_concat/merged_vcf
      axiomPoly_resource_vcf: axiomPoly_resource_vcf
      dbsnp_resource_vcf: dbsnp_vcf
      mills_resource_vcf: mills_resource_vcf
      max_gaussians: indel_max_gaussians
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
