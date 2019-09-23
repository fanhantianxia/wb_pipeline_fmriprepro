#!/bin/bash
input_dir=$1  # /data
output_dir=$2
combs_project_id=$3

echo '------Input_Config START----------'
echo 'input_dir='$input_dir
echo 'output_dir='$output_dir
echo 'combs_project_id='$combs_project_id
echo '-------Input_Config END-----------'


echo 'inspect fmriprep version....'
fmriprep --version
sleep 3s

mkdir /DataBuf 
fmriprep input_dir output_dir participant -w /DataBuf --no-submm-recon --fs-no-reconall

#--matlab config--
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v90/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64
export XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Runtime/v90/X11/app-defaults
export MCR_CACHE_VERBOSE=true
export MCR_CACHE_ROOT=/tmp


mkdir -p /file_buf
cd /file_buf
git clone https://github.com/fanhantianxia/wb_pipeline_fmriprepro.git /file_buf

mkdir /nit  
find /out/fmriprep -type f -name "*desc-preproc_bold.nii.gz" | xargs cp -t  /nit
gzip  -d  /nit/*_bold.nii.gz

#在/nit里添加config.json和fmriprep2nit.py
cp /file_buf/config.json /nit
cp /file_buf/fmriprep2nit.py /nit
cd /nit
python fmriprep2nit.py  #需要修改一下程序内部路径

chmod 777 -R /root/matlab_script/
mkdir /out/FCD  #FCD输出文件夹
/root/matlab_script/wb_pipeline_FCD /nit/nit_Input /out/FCD /file_buf/brain_mask.nii 0.6 2 0 #[Thresold] [TR] [ConnectType]

mkdir /out/FOCA  #FOCA输出文件夹
/root/matlab_script/wb_pipeline_FOCA /nit/nit_Input /out/FOCA /file_buf/brain_mask.nii 2
echo 'END'

