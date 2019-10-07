#!/bin/bash
input_dir=$1  # /data
output_dir=$2
combs_project_id=$3

FCDandFOCA_BrainMask_option=$4
FCD_Thresold=$5    #0.6
FCDandFOCA_TR=$6              #2
FCD_ConnectType=$7 #0

echo '---------------------------------------------'
time=$(date "+%Y-%m-%d %H:%M:%S")
echo "${time}"

#check all inputs
echo 'Check all inputs......'

#######--Check BrainMask--#######
if test $FCDandFOCA_BrainMask_option = "BrainMask_65x77x45" 
   then 
   BrainMask_dir=/file_buf/BrainMaskFile/BrainMask_65x77x45.nii
elif test $FCDandFOCA_BrainMask_option = "BrainMask_53x63x46" 
   then 
   FBrainMask_dir=/file_buf/BrainMaskFile/BrainMask_53x63x46.img
elif test $FCDandFOCA_BrainMask_option = "BrainMask_61x73x61" 
   then 
   BrainMask_dir=/file_buf/BrainMaskFile/BrainMask_61x73x41.img
elif [ -f $FCDandFOCA_BrainMask_option ]
   then 
   BrainMask_dir=$FCDandFOCA_BrainMask_option
else
   echo '[ERROR] Invalid format or contents of BrainMask_options, please try again!'
   echo '********FAILED********'
   exit #exit whole process
fi
#echo '[DEBUG] BrainMask_dir='$BrainMask_dir #debug


#######--Check Thresold--#######
if test -z "$FCD_Thresold" ;then  #is empty
   FCD_Thresold=0.6
   echo '[Warning] Using default FCD Thresold.'
elif test $FCD_Thresold = "[]" ;then  #is equal
   FCD_Thresold=0.6
   echo '[Warning] Using default FCD Thresold.'
else # >1 || <0 
   if [ `echo ${FCD_Thresold} | awk -v tem="1.0" '{print($1>=tem)? "1":"0"}'` -eq "1" ] # >=1 
   then 
      echo '[ERROR] Input FCD Thresold is invalid.'
      FCD_Thresold=0.6
      echo '[Warning] Using default FCD Thresold.'
   elif [ `echo ${FCD_Thresold} | awk -v tem="0.0" '{print($1<=tem)? "1":"0"}'` -eq "1" ] # <=0
   then
      echo '[ERROR] Input FCD Thresold is invalid.'
      FCD_Thresold=0.6
      echo '[Warning] Using default FCD Thresold.'
   fi
fi
echo 'FCD_Thresold='$FCD_Thresold

#######--Check TR--#######
if test -z "$FCDandFOCA_TR" ;then  #is empty
   FCDandFOCA_TR=2
   echo '[Warning] Using default FCDandFOCA TR.'
elif test $FCDandFOCA_TR = "[]" ;then  #is equal
   FCDandFOCA_TR=2
   echo '[Warning] Using default FCDandFOCA TR.'
else
   if [ `echo ${FCDandFOCA_TR} | awk -v tem="0.0" '{print($1<=tem)? "1":"0"}'` -eq "1" ] # <=0
   then
      echo '[ERROR] Input FCDandFOCA TR is invalid.'
      FCDandFOCA_TR=2
      echo '[Warning] Using default FCDandFOCA TR.'
   fi
fi
echo 'FCDandFOCA_TR='$FCDandFOCA_TR


#######--Check ConnectType--#######
if test -z "$FCD_ConnectType" ;then  #is empty
   FCD_ConnectType=0
   echo '[Warning] Using default FCD ConnectType.'
elif test $FCD_ConnectType = "[]" ;then  #is equal
   FCD_ConnectType=0
   echo '[Warning] Using default FCD ConnectType.'
fi

if [ "$FCD_ConnectType" -eq 0 ];then
   echo 'ConnectType=static'
elif [ "$FCD_ConnectType" -eq 1 ];then
   echo 'ConnectType=dynamic'
else
   echo '[ERROR] Input ConnectType is invalid.'
   FCD_ConnectType=0
   echo '[Warning] Using default FCD ConnectType.'
   echo 'ConnectType=dynamic'
fi

#display parameters
echo 'Start Project......'
echo 'Project ID:'$combs_project_id


echo '------Input_Config START----------'
echo 'input_dir='$input_dir
echo 'output_dir='$output_dir
echo 'combs_project_id='$combs_project_id
echo '-------Input_Config END-----------'


echo 'inspect fmriprep version....'
fmriprep --version


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

mkdir -p $output_dir/FCD  #FCD输出文件夹
/root/matlab_script/wb_pipeline_FCD /nit/nit_Input $output_dir/FCD /file_buf/brain_mask.nii 0.6 2 0 #[Thresold] [TR] [ConnectType]

mkdir -p $output_dir/FOCA  #FOCA输出文件夹
/root/matlab_script/wb_pipeline_FOCA /nit/nit_Input $output_dir/FOCA /file_buf/brain_mask.nii 2
echo 'END'

