## Human reference (host depletion)

Human reference genomes and Bowtie2 indices are not versioned due to size.

Users must provide a Bowtie2 index, e.g.:

```bash
bowtie2-build hg38.fa hg38

Then configure the pipeline with:

--host_index path/to/hg38