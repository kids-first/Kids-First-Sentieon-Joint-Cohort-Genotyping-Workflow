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
