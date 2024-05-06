# Kids First-Sentieon Joint Cohort Call Notebook
Due to platform limitations, running the easier workflow may not be feasible when cohorts exceed 200 samples, due to scatter job size limitations.
[This notebook](../workflow/kf-joint-cohort-call-advanced-setup.ipynb) can be used to set up the split by chromosome jobs, in which N jobs are created to split X files per instance, depending on yor math.
Then with sensible tagging and sorting, the outputs from these jobs can be reliable pass to the Sentieon GVCFtyper to create the final product.
In the end, you'll want to delete all files with the `INTERMEDIATE` tag to avoid excessive storage costs on files that are likely cheaper to regenerate as needed than store indefinitely