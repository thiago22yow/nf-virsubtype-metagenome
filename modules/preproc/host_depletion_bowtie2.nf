process HOST_DEPLETION {

    tag "${sample_id}"

    conda 'envs/host_depletion.yml'

    input:
        tuple val(sample_id), path(r1), path(r2), val(host)

    output:
        tuple val(sample_id),
              path("${sample_id}_R1.hostdepl.fastq.gz"),
              path("${sample_id}_R2.hostdepl.fastq.gz"),
              val(host)

    script:
    """
    bowtie2 -x ${params.host_index} \
        -1 ${r1} -2 ${r2} \
        --very-sensitive \
        --un-conc-gz ${sample_id}_R%.hostdepl.fastq.gz \
        -S /dev/null
    """
}


