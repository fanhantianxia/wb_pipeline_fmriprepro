#!/bin/bash
input_dir=$1  # /data
output_dir=$2
combs_project_id=$3
FCD_BrainMask_option=$4
FCD_Thresold=$5    #0.6
FCD_TR=$6          #2
FCD_ConnectType=$7 #0


#workdir=/home/yufan/Desktop/FCD/data_buf  #debug route
#echo '[DEBUG]'$workdir
mkdir -p /root/FCD/data_buf 
workdir=/root/FCD/data_buf  


echo '---------------------------------------------'
time=$(date "+%Y-%m-%d %H:%M:%S")
echo "${time}"

#check all inputs
echo 'Check all inputs......'

#######--Check BrainMask--#######
if test $FCD_BrainMask_option = "BrainMask_65x77x45" 
   then 
   FCD_BrainMask_dir=/file_buf/BrainMaskFile/BrainMask_65x77x45.nii
elif test $FCD_BrainMask_option = "BrainMask_53x63x46" 
   then 
   FCD_BrainMask_dir=/file_buf/BrainMaskFile/BrainMask_53x63x46.img
elif test $FCD_BrainMask_option = "BrainMask_61x73x61" 
   then 
   FCD_BrainMask_dir=/file_buf/BrainMaskFile/BrainMask_61x73x41.img
elif [ -f $FCD_BrainMask_option ]
   then 
   FCD_BrainMask_dir=$FCD_BrainMask_option
else
   echo '[ERROR] Invalid format or contents of BrainMask_options, please try again!'
   echo '********FAILED********'
   exit #exit whole process
fi
#echo '[DEBUG] FCD_BrainMask_dir='$FCD_BrainMask_dir #debug


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
if test -z "$FCD_TR" ;then  #is empty
   FCD_TR=2
   echo '[Warning] Using default FCD TR.'
elif test $FCD_TR = "[]" ;then  #is equal
   FCD_TR=2
   echo '[Warning] Using default FCD TR.'
else
   if [ `echo ${FCD_TR} | awk -v tem="0.0" '{print($1<=tem)? "1":"0"}'` -eq "1" ] # <=0
   then
      echo '[ERROR] Input FCD TR is invalid.'
      FCD_TR=2
      echo '[Warning] Using default FCD TR.'
   fi
fi
echo 'FCD_TR='$FCD_TR


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

#config environment var
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v90/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64
export XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Runtime/v90/X11/app-defaults
export MCR_CACHE_VERBOSE=true
export MCR_CACHE_ROOT=/tmp


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
     cd ./$InputFile
     #second unzip
     find . -type f -name "*.zip" | xargs -n1 unzip 
     rm *.zip
     cd .. #back to workdir

     #echo 'caluFCD'
     mkdir -p $output_dir/FCD/$InputFile #position of result 
     /root/matlab_script/wb_pipeline_FCD $workdir/$InputFile $output_dir/FCD/$InputFile $FCD_BrainMask_dir $FCD_Thresold $FCD_TR $FCD_ConnectType   
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
