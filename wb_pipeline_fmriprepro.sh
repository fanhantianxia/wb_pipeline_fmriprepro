#!/bin/bash
#mode=$1  
echo '********test********'

if test mode = "wb_pipeline_calcFCD"
	then
	./wb_pipeline_calcFCD.sh $2 $3 $4 $5 $6 $7 $8
elif test mode = "wb_pipeline_calcFOCA"
	then
	./wb_pipeline_calcFOCA.sh $2 $3 $4 $5 $6
elif test mode = "wb_pipeline_calcFMRIPREP"
	then
	./wb_pipeline_calcFMRIPREP.sh $2 $3 $4 $5 $6 $7 $8 $9 $10
elif test mode = "wb_pipeline_calcALL"
	then
	./wb_pipeline_calcALL.sh $2 $3 $4 $5 $6 $7 $8 $9 $10
else
    echo '********FAILED********'
	exit
fi
