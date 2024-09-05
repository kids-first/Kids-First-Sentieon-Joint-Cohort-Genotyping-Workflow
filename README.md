# Kids First-Sentieon Joint Cohort Calling

This is a beta workflow. It is not currently used in production, but it's output is more than serviceable.
An efficient, fast, and cost effective workflow for joint calling cohorts up to ~4000 individuals on the CAVATICA platform.
You will likely need to have installed [sbpack](https://pypi.org/project/sbpack/) to push the necessary apps into your project, and it is recommended to have the python packages listed in `python_pip_requirements.txt` installed.
Both workflows have limited implementations of the [`GVCFtyper` algo](https://support.sentieon.com/manual/usages/general/#gvcftyper-algorithm) which is part of the [Sentieon driver library](https://support.sentieon.com/manual/usages/general/#driver-binary).
Currently, VQSR is not part of this workfow, but is available to run after this one.
Please see the [Kids First-Sentieon VQSR Equivalent Workflow](docs/KF_SENTIEON_VQSR.md) for more info on that.
For any question/comments/support request, please email support@kidsfirstdrc.org
<p align="center">
 <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png" alt="data service logo"/>
</p>

<p align="center">
<a href="https://github.com/kids-first/Kids-First-Sentieon-Joint-Cohort-Genotyping-Workflow/blob/main/LICENSE"><img src="https://img.shields.io/github/license/kids-first/kf-template-repo.svg?style=for-the-badge"></a>
</p>

## [Preferred Cohort Calling Workflow](docs/KF_COHORT_JG_SINGLE_WF.md)
This workflow runs on the CAVATICA platform with few parameters necessary to run.
The platform has an internal workflow scatter limit of ~2200 files, which means, **if your cohort size is greater than this, it will not run!**
To load this app into your project, follow the instructions in the [sbpack](https://pypi.org/project/sbpack/) install to load `workflow/kf-joint-cohort-call-by-chr-wf.cwl`

## [Large Cohort Calling Workflow](docs/KF_NOTEBOOK_JG_WORKFLOW.md)
This notebook can be run locally or copied to a CAVATICA Data Studio Analysis session.
If your cohort is >2200 samples, but projected to use less than 4TB per split job and chromosome call job, you can use this.
To estimate the amount of disk space required, we recommend taking the average file size of your cohort, and assuming even distribution of file size by chromosome, multiply it by the proportion if the size of the genome to be used, and double it. For example, if the average file size were 7.2 GB, and, using chr 1-22,X,Y as our total genome, chr1 is the largest and take up about 0.08 of total bases, and you want to leave room for the joint call result for that chromosome so:
```
x = 4000 GB/( 7.2 GB * 0.16 )
x ~ 3,472 files
```
Therefore, in this scenario, if your cohort is 3,472 files, then you can use this method
Similar to the Preferred method, you will push two apps this time, `workflow/split_vcf_mini_wf.cwl` and `tools/bcftools_shard_vcf.cwl` to your project

## Loading the Workflows and Apps
Since this is a beta project, it is not yet in the CAVATICA apps.
It is recommended that you push them to the platform from **git releases only.**
Git releases typically have had some kind of testing and are more likely to work than from main or any other branch.

## Cost and run time estimates
Based on using the Advanced Cohort Calling Workflow on a cohort of 2303 samples:
Split cost: $60.96; Split Run Time: ~1.5 hours
Sentieon GVCFTyper: $231.34, Call run times varied by chr size, 1-7 hours, median ~3.5 hours