#!/bin/bash

# mprof run --include-children bash 03_clean_up_result.sh
# mprof plot

# Delete the runtime files in the very end, if not deleted previously.
password_file_path=/media/hugolab/DataRAID1/projects/workflows/password.txt
current_wdl_runtime_directory="$PWD"
echo $(cat $password_file_path) | sudo -S rm -r ${current_wdl_runtime_directory}/cromwell-executions ${current_wdl_runtime_directory}/cromwell-workflow-logs

echo "The script runs up to here!"
