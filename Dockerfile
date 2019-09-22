FROM poldracklab/fmriprep
MAINTAINER Yufan Zhang <zyf15816794709@163.com>

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

#ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/MATLAB/MATLAB_Runtime/v90/runtime/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/bin/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/os/glnxa64:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64/server:/usr/local/MATLAB/MATLAB_Runtime/v90/sys/java/jre/glnxa64/jre/lib/amd64
#ENV XAPPLRESDIR=/usr/local/MATLAB/MATLAB_Runtime/v90/X11/app-defaults
#ENV MCR_CACHE_VERBOSE=true
#ENV MCR_CACHE_ROOT=/tmp

#RUN mkdir -p /app_file
#RUN cd /app_file
#RUN git clone https://github.com/fanhantianxia/wb_fmri_pipeline_tool.git /app_file  #tool_dir
#RUN mkdir /root/matlab_script/
#RUN cp /app_file/wb_pipeline_FCD /root/matlab_script/
#RUN cp /app_file/wb_pipeline_FOCA /root/matlab_script/

RUN mkdir -p /script
RUN cd /script

RUN git clone https://github.com/fanhantianxia/wb_fmri_pipeline.git 
ADD main.sh /root/main.sh
RUN chmod a+x /root/main.sh
RUN rm -rf /script
ENTRYPOINT ["/root/main.sh"]
