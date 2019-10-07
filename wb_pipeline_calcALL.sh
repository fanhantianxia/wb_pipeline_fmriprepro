#!/bin/bash
input_dir=$1  # /data
output_dir=$2
combs_project_id=$3

FCDandFOCA_BrainMask_option=$4
FCD_Thresold=$5    #0.6
FCDandFOCA_TR=$6              #2
FCD_ConnectType=$7 #0

preprocessing_options=$8
Surface_preprocessing_options=$9

mkdir -p /root/FMRIPREP/data_buf
workdir=/root/FMRIPREP/data_buf 

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
   BrainMask_dir=/file_buf/BrainMaskFile/BrainMask_53x63x46.img
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

if test -z "$preprocessing_options" 
   then
   preprocessing_options_content=
elif test $preprocessing_options = "[]" 
   then 
   preprocessing_options_content=
elif test $preprocessing_options = "OnlyAnat" 
   then 
   preprocessing_options_content='--anat-only'
   echo 'OK'
elif test $preprocessing_options="All" 
   then 
   preprocessing_options_content=
else
   echo '[ERROR] Invalid format or contents of preprocessing_options, please try again!'
   echo '********FAILED********'
   exit #exit whole process
fi
echo 'preprocessing_options_content='$preprocessing_options_content


if test -z "$Surface_preprocessing_options" 
   then
   Surface_preprocessing_options_content='--no-submm-recon --fs-no-reconall'
elif test $Surface_preprocessing_options = "[]" 
   then 
   Surface_preprocessing_options_content='--no-submm-recon --fs-no-reconall'
elif test $Surface_preprocessing_options = "Disable" 
   then 
   Surface_preprocessing_options_content='--no-submm-recon --fs-no-reconall'
elif test $Surface_preprocessing_options = "FreeSurfer" 
   then 
   Surface_preprocessing_options_content='--no-submm-recon'
   echo 'OK'
elif test $Surface_preprocessing_options = "SubmmRecon" 
   then 
   Surface_preprocessing_options_content='--fs-no-reconall'
elif test $Surface_preprocessing_options = "All" 
   then 
   Surface_preprocessing_options_content=
else
   echo '[ERROR] Invalid format or contents of Surface_preprocessing_options, please try again!'
   echo '********FAILED********'
   exit #exit whole process
fi
echo 'Surface_preprocessing_options_content='$Surface_preprocessing_options_content




#display parameters
echo 'Start Project......'
echo 'Project ID:'$combs_project_id


#loading data and calculating
echo 'loading data and calculating......'
string=$input_dir
array=(${string//,/ })
cd $workdir  
#first unzip
for SingleZip in ${array[@]}
do
   #echo '[DEBUG] '$SingleZip #debug
   unzip $SingleZip -d $workdir #input_dir connect to workdir
done


fmriprep --version
mkdir /DataBuf 

#--matlab config--
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v90/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64
export XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Runtime/v90/X11/app-defaults
export MCR_CACHE_VERBOSE=true
export MCR_CACHE_ROOT=/tmp

ZipNum=0
Skipped_FileNum=0
dir=$(ls -l $workdir  |awk '/^d/ {print $NF}') #give all files name in workdir
for InputFile in $dir
do
   let ZipNum++
   echo '------------------------'
   echo 'No. of subjects:'$ZipNum
   
   if [ `ls ./$InputFile | wc -c` -eq 0 ] #check if file exits
   then 
     echo "[Warning] file is null"
     echo "[Warning] Fail to load file:"$InputFile
     arr[Skipped_FileNum]=$InputFile
     let Skipped_FileNum++
   else
     mkdir -p $output_dir/FMRIPREP/$InputFile
     fmriprep $workdir/$InputFile $output_dir/FMRIPREP/$InputFile participant -w /DataBuf $preprocessing_options_content $Surface_preprocessing_options_content
   fi 
done




mkdir -p /file_buf
cd /file_buf
git clone https://github.com/fanhantianxia/wb_pipeline_fmriprepro.git /file_buf

mkdir /nit  
find $output_dir/FMRIPREP/$InputFile -type f -name "*desc-preproc_bold.nii.gz" | xargs cp -t  /nit
gzip  -d  /nit/*_bold.nii.gz

#在/nit里添加config.json和fmriprep2nit.py
cp /file_buf/config.json /nit
cp /file_buf/fmriprep2nit.py /nit
cd /nit
python fmriprep2nit.py  #需要修改一下程序内部路径

mkdir -p $output_dir/FCD  #FCD输出文件夹
/root/matlab_script/wb_pipeline_FCD /nit/nit_Input $output_dir/FCD/$InputFile $BrainMask_dir $FCD_Thresold $FCDandFOCA_TR $FCD_ConnectType 

mkdir -p $output_dir/FOCA  #FOCA输出文件夹
/root/matlab_script/wb_pipeline_FOCA /nit/nit_Input $output_dir/FOCA/$InputFile $BrainMask_dir $FCDandFOCA_TR


echo '------------------------'
if test -z "$Skipped_FileNum"
then
   echo '********SUCCESS********'
elif test $Skipped_FileNum = $ZipNum
then
   echo '********FAILED********'
else
   echo '********CalculatedSubjects********' 
   let CalculatedNum=$ZipNum-$Skipped_FileNum
   echo 'No. of Calculated Subjects:'$CalculatedNum
   echo '********SkippedSubjects********'
   echo 'No. of Skipped Subjects:'$Skipped_FileNum
   
   for value in ${arr[@]}
   do
     echo 'Skipped_filename:'$value
   done
   echo '********SUCCESS********'
fi
