# [Kids First-Sentieon Joint Cohort Calling Workflow Beta](../workflow/kf-joint-cohort-call-by-chr-wf.cwl)
This workflow is takes a set of gVCFs and an indexed reference FASTA to create a joint-called cohort VCF.
The input gVCFs are sharded by chromosome. To accelerate the process, the sharding is done across 60 instances, each of which is processing 12 files at a time.
Next, gVCF shards that share a common chromosome are gathered and passed to Sentieon GVCFtyper, producing one joint VCF per chromosome.
If the user supplies a dbSNP vcf at run time, the outputs will also be annotated with `rs_` IDs in the `ID` column of the VCF.

![data service logo](https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png)

## Limitations
Two main limitations currently (as of May 2024) exist for running this cohort workflow on CAVATICA:
 - Cohort Size
 - File input size

Cohort size **must be less than ~2200 samples** to run, otherwise the platform will will quit immediately with error:
```
The scheduled job root is too large to be executed. Please contact support@sbgenomics.com for further assistance if needed.
```
CAVATICA instances, by default, start with 1TB of EBS storage. The storage can be increased through the `Execution Settings` all the way up to 4TB.
If 4TB is insufficient to process your cohort, contact CAVATICA support for assistance. Alternatively, try refining the cohort or limiting the sites of interest.

## Inputs
### Required
 - `reference`: Indexed FASTA file reference. Should be the same one used to create the input gVCFs
 - `input_vcf`: Indexed gVCF files to perform cohort calling on. It's recommended that the [GATK Haplotyper caller workflow](https://cavatica.sbgenomics.com/public/apps/cavatica/apps-publisher/kfdrc-gatk-haplotypecaller-workflow) or [Sentieon equivalent](https://cavatica.sbgenomics.com/public/apps/cavatica/apps-publisher/kfdrc_sentieon_gvcf_wf) has been used to generate each of these inputs. If gVCFs were obtained from Gabriella Miller Kids First (GMKF), it will meet this recommendation.
 - `sentieon_license`: Sentieon license server host and port in format `0.0.0.0:0000`. Is set by default by the workflow, but can be changed if circumstances require it.
### Recommended
 - `dbSNP`: Indexed dbSNP file to add common variant annotation if `ID` field

### Optional
 - `fai_subset`: Parameter used to set which chromosome are to be used based on the FASTA index file. It's generally recommended to use the canonical chromosomes (chr1-22,X,Y). By default, this parameter is set to `24` to capture those first 24 chromosomes of the FASTA index.
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
   - EBS storage: `2048` up to `4096`
   - Number of parallel instances: `60`. Most users have an `80` max limit per account
