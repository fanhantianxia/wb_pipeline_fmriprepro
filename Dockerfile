FROM daocloud.io/fanhan/wb_fmriprep:latest
MAINTAINER Yufan Zhang <zyf15816794709@163.com>

RUN fmriprep --version

RUN apt-get update && apt-get install -y python-dev python-setuptools python-numpy python-scipy zlib1g-dev python-matplotlib python-nose 
RUN easy_install pip

RUN apt-get install tree
RUN pip install nibabel
RUN pip install numpy
RUN apt-get -y install git

RUN apt-get install -y libpng-dev libfreetype6-dev pkg-config zip python-vtk
RUN mkdir /mcr-install
WORKDIR /mcr-install

#download matlab runtime
RUN apt-get install -y wget
RUN wget -nv http://www.mathworks.com/supportfiles/downloads/R2015b/deployment_files/R2015b/installers/glnxa64/MCR_R2015b_glnxa64_installer.zip
RUN unzip MCR_R2015b_glnxa64_installer.zip

#config matlab runtime
WORKDIR /mcr-install
RUN ./install -mode silent -agreeToLicense yes
RUN cd /
RUN rm -Rf /mcr-install

RUN mkdir -p /app_file
RUN cd /app_file
RUN git clone https://github.com/fanhantianxia/wb_fmri_pipeline_tool.git /app_file  #tool_dir
RUN mkdir /root/matlab_script/
RUN cp /app_file/wb_pipeline_FCD /root/matlab_script/
RUN cp /app_file/wb_pipeline_FOCA /root/matlab_script/
RUN chmod 777 -R /root/matlab_script/

RUN mkdir -p /file_buf
RUN mkdir -p /script
RUN cd /script

RUN git clone https://github.com/fanhantianxia/wb_pipeline_fmriprepro.git 
ADD BrainMaskFile /file_buf/BrainMaskFile
ADD wb_pipeline_calcFCD.sh /root/wb_pipeline_calcFCD.sh
ADD wb_pipeline_calcFOCA.sh /root/wb_pipeline_calcFOCA.sh
ADD wb_pipeline_calcFMRIPREP.sh /root/wb_pipeline_calcFMRIPREP.sh
ADD wb_pipeline_calcALL.sh /root/wb_pipeline_calcALL.sh

RUN chmod 777 -R /root/
RUN rm -rf /script
