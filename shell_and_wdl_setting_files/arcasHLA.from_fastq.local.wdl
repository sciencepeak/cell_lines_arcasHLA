version 1.0
workflow MyBestWorkflow {
    input {
        # the sample_id in an entity table stores some raw information of the samples
        # The base_file_name is the actual, concise, and actual sample_name throughout the code.
        String base_file_name

        # Required for (;-concatednated) fastq files
        File fastq_r1
        File? fastq_r2

        Boolean? single_endness
        String? strandness

        Int thread_number

        File hisat_index_path_file

    }

    call SplitFastqNames {
        input:
            sample_name = base_file_name,
            fastq_r1_string = fastq_r1,
            fastq_r2_string = fastq_r2
    }

    call Hisat2FastqToSam {
        input:
            sample_name = base_file_name,
            fastq_list_files = SplitFastqNames.fastq_list_files,
            hisat_index_path_file = hisat_index_path_file,
            single_endness = single_endness,
            strandness = strandness,
            thread_number = thread_number
    }

    call SamOrBamToCoordinateSortedBam {
        input:
            sample_name = base_file_name,
            input_sam_or_bam = Hisat2FastqToSam.initially_mapped_sam,
            thread_number = thread_number
    }

    call PicardRemoveDuplicates {
        input:
            sample_name = base_file_name,
            input_bam = SamOrBamToCoordinateSortedBam.coordinate_sorted_bam
    }


    call RunarcasHLA {
        input:
            sample_name = base_file_name,
            bam_file_name = PicardRemoveDuplicates.duplicates_removed_bam,
            thread_number = thread_number
    }

    # Output files of the workflows.
    output {
        File final_output_genes_json_file = RunarcasHLA.output_genes_json_file
        File final_output_genotype_json_file = RunarcasHLA.output_genotype_json_file
    }
}

task SplitFastqNames {
    input {
        String sample_name
        String fastq_r1_string
        String? fastq_r2_string
    }

    command {
        echo "${fastq_r1_string}" | tr ";" "\n" > ${sample_name}.fastq_r1_list.txt
        echo "${fastq_r2_string}" | tr ";" "\n" > ${sample_name}.fastq_r2_list.txt
    }

    output {
        Array[File] fastq_list_files = glob("*_list.txt")
    }

    runtime {
        disks: "local-disk 375 SSD"
        docker: "ubuntu:18.04"
    }
}

task Hisat2FastqToSam {
    input {
        String sample_name
        Array[File]+ fastq_list_files
        File hisat_index_path_file
        Boolean? single_endness
        String? strandness
        Int thread_number
    }

    Array[File] fastq_r1_list = read_lines(fastq_list_files[0])
    Array[File]? fastq_r2_list = read_lines(fastq_list_files[1])

    Array[File] hisat_index_files = read_lines(hisat_index_path_file)
    File first_index_file = hisat_index_files[0]

    Boolean single_end_argument = select_first([single_endness, false])
    String strandness_argument = if defined(strandness) then "--rna-strandness " + strandness + " " else ""

    command <<<
        if [[ "~{single_end_argument}" == true ]]
            then
                echo "The single end input is detected"
                files=$(echo "-U "~{sep="," fastq_r1_list})
            else
                echo "The paired end input is detected"
                files=$(echo "-1 "~{sep="," fastq_r1_list}" -2 "~{sep="," fastq_r2_list})
        fi

        echo the input file paths: $files

        # Could not locate a HISAT2 index corresponding to basename? Do this:
        hisat_prefix_complete_path=~{first_index_file}
        # https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html#Shell-Parameter-Expansion
        hisat_prefix=${hisat_prefix_complete_path%%.*.ht2}
        echo the generated hisat prefix: $hisat_prefix

        /usr/local/bin/hisat2 -p ~{thread_number} --dta -x $hisat_prefix ~{strandness_argument} $files -S ~{sample_name}.initially_mapped.sam
    >>>

    output {
        File initially_mapped_sam = glob("*.initially_mapped.sam")[0]
    }

    runtime {
        cpu: thread_number
        memory: "16G"
        disks: "local-disk 750 SSD"
        docker: "zlskidmore/hisat2:2.1.0"
    }
}

task SamOrBamToCoordinateSortedBam {
    input {
        String sample_name
        File input_sam_or_bam
        Int thread_number
    }

    command {
        /usr/local/bin/samtools sort -@ ${thread_number} -l 9 -o ${sample_name}.coordinate_sorted.bam ${input_sam_or_bam}
    }

    output {
        File coordinate_sorted_bam = "${sample_name}.coordinate_sorted.bam"
    }

    runtime {
        cpu: thread_number
        memory: "8G"
        disks: "local-disk 750 SSD"
        docker: "zlskidmore/samtools:1.15.1"
    }
}

task PicardRemoveDuplicates {
    input {
        String sample_name
        File input_bam
    }

    command {
        java -Xmx16g -jar /usr/picard/picard.jar MarkDuplicates I=${input_bam} O=${sample_name}.duplicates_removed.bam ASSUME_SORT_ORDER=coordinate METRICS_FILE=${sample_name}.duplicates_metrics.txt QUIET=true COMPRESSION_LEVEL=9 VALIDATION_STRINGENCY=LENIENT REMOVE_DUPLICATES=true
    }

    output {
        File duplicates_removed_bam = "${sample_name}.duplicates_removed.bam"
        File duplicates_metrics_txt = "${sample_name}.duplicates_metrics.txt"
    }

    runtime {
        memory: "32G"
        disks: "local-disk 750 SSD"
        docker: "broadinstitute/picard:2.27.4"
    }
}

task RunarcasHLA {

    input {
        String sample_name
        File bam_file_name
        Int thread_number
    }

    command {
        # Rename the bam files
        cp ${bam_file_name} ${sample_name}.bam

        arcasHLA extract -t ${thread_number} ${sample_name}.bam
        arcasHLA genotype -t ${thread_number} ${sample_name}.extracted.1.fq.gz ${sample_name}.extracted.2.fq.gz
    }

    output {
        File output_genes_json_file = "${sample_name}.genes.json"
        File output_genotype_json_file = "${sample_name}.genotype.json"
    }

    runtime {
        memory: "32G"
        cpu: thread_number
        disks: "local-disk 375 SSD"
        docker: "wallen/arcashla:0.2.5"
    }

}
