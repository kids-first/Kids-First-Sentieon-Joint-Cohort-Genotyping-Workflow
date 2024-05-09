# Kids First-Sentieon Joint Cohort Call Notebook
<p align="center">
 <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png" alt="data service logo"/>
</p>

Due to platform limitations, running the Preferred workflow may not be feasible when cohorts exceed 2200 samples, due to scatter job size limitations.
If your cohort is >2200 samples, but projected to use less than 4TB per split job and chromosome call job, you can use this.
To estimate the amount of disk space required, we recommend taking the average file size of your cohort, and assuming even distribution of file size by chromosome, multiply it by the proportion if the size of the genome to be used, and double it. For example, if the average file size were 7.2 GB, and, using chr 1-22,X,Y as our total genome, chr1 is the largest and take up about 0.08 of total bases, and you want to leave room for the joint call result for that chromosome so:
```
x = 4000 GB/( 7.2 GB * 0.16 )
x ~ 3,472 files
```
Therefore, in this scenario, if your cohort is 3,472 files, then you can use this method.
If your cohort exceeds the platform limitations, you can either:
 - Attempt to further sub-categorize your cohort into smaller cohorts to run
 - Focus on specific intervals from each chromosome

The latter run mode is not yet available, but may be some time in 2024.

[This notebook](../workflow/kf-joint-cohort-call-advanced-setup.ipynb) can be used to set up the split by chromosome jobs, in which N jobs are created to split X files per instance, depending on your math.
Then with sensible tagging and sorting, the outputs from these jobs can be reliably passed to the Sentieon GVCFtyper to create the final product.
In the end, you'll want to delete all files with the `INTERMEDIATE` tag to avoid excessive storage costs. These files can be quickly and cheaply regenerated, as needed.