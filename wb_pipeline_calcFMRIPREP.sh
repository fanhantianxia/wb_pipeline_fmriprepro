#!/bin/bash
input_dir=$1  # /data
output_dir=$2  # /out
combs_project_id=$3

preprocessing_options=$4
Surface_preprocessing_options=$5
#User define
UserOption01=$6
UserOption02=$7
UserOption03=$8
UserOption04=$9

mkdir -p /root/FMRIPREP/data_buf
workdir=/root/FMRIPREP/data_buf  

echo '---------------------------------------------'
time=$(date "+%Y-%m-%d %H:%M:%S")
echo "${time}"

#check all inputs
echo 'Check all inputs......'

cd /usr/local/miniconda/bin/
fmriprep --version

:<<!
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


mkdir /DataBuf 

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
     mkdir -p $output_dir/FMRIPREP/$InputFile #position of result 
     /usr/local/miniconda/bin/fmriprep $workdir/$InputFile $output_dir/FMRIPREP/$InputFile participant -w /DataBuf $preprocessing_options_content $Surface_preprocessing_options_content $UserOption01 $UserOption02 $UserOption03 $UserOption04
   fi 
done

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
!
