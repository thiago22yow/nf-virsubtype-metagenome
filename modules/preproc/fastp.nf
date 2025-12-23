process FASTP_TRIM {

    tag "${sample_id}"

    conda 'envs/fastp.yml'

    input:
        tuple val(sample_id), path(r1), path(r2), val(host)

    output:
        tuple val(sample_id),
              path("${sample_id}_R1.trimmed.fastq.gz"),
              path("${sample_id}_R2.trimmed.fastq.gz"),
              val(host)

    script:
    """
    fastp \
      -i ${r1} -I ${r2} \
      -o ${sample_id}_R1.trimmed.fastq.gz \
      -O ${sample_id}_R2.trimmed.fastq.gz \
      --json ${sample_id}.fastp.json \
      --html ${sample_id}.fastp.html
    """
}

