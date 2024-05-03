# Kids First-Sentieon Joint Cohort Calling

This is a work in progress and under active development.
An efficient, fast, and cost effective workflow for joint calling cohorts up to ~4000 individuals on the CAVATICA platform

<p align="center">
<img src="docs/drc_logo.png" alt="Kids First repository logo" width="660px" />
</p>
<p align="center">
<a href="https://github.com/kids-first/Kids-First-Sentieon-Joint-Cohort-Genotyping-Workflow/blob/main/LICENSE"><img src="https://img.shields.io/github/license/kids-first/kf-template-repo.svg?style=for-the-badge"></a>
</p>

## [Easy Cohort Calling Workflow](docs/KF_COHORT_JG_SINGLE_WF.md)
This workflow runs on the CAVATICA platform with few parameters necessary to run.
The platform has an internal workflow scatter limit of ~2200 files, which means, **if your cohort size is greater than this, it will not run!**

## [Advanced Cohort Calling Workflow](docs/KF_NOTEBOOK_JG_WORKFLOW.md)
This notebook can be run locally or copied to a CAVATICA Data Studio Analysis session.
If your cohort is >2200 samples, but projected to use less than 4TB per split job and chromosome call job, you can use this.

## Cost and run time estimates
Based on using the Advanced Cohort Calling Workflow on a cohort of 2303 samples:
Split cost: $60.96; Split Run Time: ~1.5 hours
Sentieon GVCFTyper: $231.34, Call run times varied by chr size, 1-7 hours, median ~3.5 hours