# Kids First-Sentieon Joint Cohort Call Notebook
Due to platform limitations, running the Preferred workflow may not be feasible when cohorts exceed 2200 samples, due to scatter job size limitations.

<p align="center">
 <img src="https://github.com/d3b-center/d3b-research-workflows/raw/master/doc/kfdrc-logo-sm.png" alt="data service logo"/>
</p>


[This notebook](../workflow/kf-joint-cohort-call-advanced-setup.ipynb) can be used to set up the split by chromosome jobs, in which N jobs are created to split X files per instance, depending on your math.
Then with sensible tagging and sorting, the outputs from these jobs can be reliably passed to the Sentieon GVCFtyper to create the final product.
In the end, you'll want to delete all files with the `INTERMEDIATE` tag to avoid excessive storage costs. These files can be quickly and cheaply regenerated, as needed.