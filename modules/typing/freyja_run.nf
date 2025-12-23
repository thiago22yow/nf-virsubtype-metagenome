process FREYJA_RUN {

    tag "${sample_id}"

    publishDir "${params.outdir}/typing/freyja",
               mode: 'copy',
               overwrite: true

    conda "${projectDir}/envs/freyja.yml"

    input:
        tuple val(sample_id), path(r1), path(r2)

    output:
        tuple val(sample_id),
              path("${sample_id}.freyja.tsv")

    script:
    """
    set -euo pipefail

    minimap2 -ax sr ${params.sc2_ref} ${r1} ${r2} | \
      samtools sort -o ${sample_id}.sc2.bam

    samtools index ${sample_id}.sc2.bam

    freyja variants ${sample_id}.sc2.bam \
      --variants ${sample_id}.variants.tsv \
      --depths   ${sample_id}.depths.tsv \
      --ref      ${params.sc2_ref}

    if ! freyja demix ${sample_id}.variants.tsv ${sample_id}.depths.tsv \
        --output ${sample_id}.freyja.tsv \
        --depthcutoff 10 ; then
      printf "lineage\tabundance\nNO_SC2_DETECTED\t0.0\n" > ${sample_id}.freyja.tsv
    fi
    """
}
