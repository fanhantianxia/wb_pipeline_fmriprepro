#!/bin/bash

input_dir=$1  # /data
output_dir=$2
combs_project_id=$3

FCD_Thresold=$4    #0.6
FCD_TR=$5          #2
FCD_ConnectType=$6 #0

echo $FCD_Thresold
echo $FCD_TR
echo $FCD_ConnectType

#--matlab config--
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v90/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64
export XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Runtime/v90/X11/app-defaults
export MCR_CACHE_VERBOSE=true
export MCR_CACHE_ROOT=/tmp

#mkdir output_dir/FCD  #FCD输出文件夹
/root/matlab_script/wb_pipeline_FCD $input_dir $output_dir /file_buf/brain_mask.nii $FCD_Thresold $FCD_TR FCD_ConnectType 
#[Thresold] [TR] [ConnectType]

echo 'END'
