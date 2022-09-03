#!/bin/bash

# modify these information for each script.
project_directory=/media/hugolab/DataRAID1/projects2/workflows/cell_lines/arcasHLA
program_name=arcasHLA.from_fastq.local
# batch_method=by_folder
batch_method=by_file

whether_delete_cromwell_executions=false

password_file_path=/media/hugolab/DataRAID1/projects/workflows/password.txt

# These information should be constant
parental_directory=${project_directory}/local_json_inputs_directory/${batch_method}
finished_directory=${project_directory}/result_directory

script_file=${program_name}.wdl
option_file=local_options.json

if [[ $batch_method == "by_file" ]]
	then
		echo "Now the job is run by file"
		
		for input_file in $(find $parental_directory -type f -name "*.json" | sort)
			do
				finished_sample_names=$(ls $finished_directory | cut -d "." -f 1 | sort | uniq)
				to_run_sample_name=$(basename $input_file | cut -d "." -f 1)
				
				if [[ "${finished_sample_names[@]}" =~ "${to_run_sample_name}" ]]; then
					# whatever you want to do when array contains value
					echo $to_run_sample_name has run, will do nothing.
				fi

				if [[ ! "${finished_sample_names[@]}" =~ "${to_run_sample_name}" ]]; then
					# whatever you want to do when array doesn't contain value
					echo $to_run_sample_name has not run, will run now.
					time java -Xmx168g -jar $CROMWELL run $script_file --inputs $input_file --options $option_file
					if [[ $whether_delete_cromwell_executions == "true" ]]; then
						echo $(cat ${password_file_path}) | sudo -S rm -r cromwell-executions
					fi
				fi
			done
		
elif [[ $batch_method == "by_folder" ]]
	then
		echo "Now the job is run by folder"
		
		for input_folder in $(find $parental_directory -type d -name "input_folder*" | sort)
			do
				for input_file in $(find $input_folder -type f -name "*.json" | sort)
					do
						finished_sample_names=$(ls $finished_directory | cut -d "." -f 1 | sort | uniq)
						to_run_sample_name=$(basename $input_file | cut -d "." -f 1)

						if [[ "${finished_sample_names[@]}" =~ "${to_run_sample_name}" ]]; then
							# whatever you want to do when array contains value
							echo $to_run_sample_name has run, will do nothing.
						fi

						if [[ ! "${finished_sample_names[@]}" =~ "${to_run_sample_name}" ]]; then
							# whatever you want to do when array doesn't contain value
							echo $to_run_sample_name has not run, will run now.
							time java -Xmx168g -jar $CROMWELL run $script_file --inputs $input_file --options $option_file &
						fi
					done
				wait
				if [[ $whether_delete_cromwell_executions == "true" ]]; then
					echo $(cat ${password_file_path}) | sudo -S rm -r cromwell-executions
				fi
			done
		
else
	echo "the method is not found"
fi

echo "The script runs up to here!"