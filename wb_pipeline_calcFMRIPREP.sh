#!/bin/bash
input_dir=$1  # /data
output_dir=$2
combs_project_id=$3

echo '********** wb_pipeline_calcFMRIPREP START **********'
sleep 1s
echo '\n'
echo '-------Input_Config START---------'
echo 'input_dir='$input_dir
echo 'output_dir='$output_dir
echo 'combs_project_id='$combs_project_id
echo '--------Input_Config END----------'
sleep 3s


echo '-------------fmriprep version--------------'
fmriprep --version
sleep 3s

echo '--------------enter fmriprep---------------'
mkdir /DataBuf 
fmriprep $input_dir $output_dir participant -w /DataBuf --no-submm-recon --fs-no-reconall


echo '*********** wb_pipeline_calcFMRIPREP END ***********'
