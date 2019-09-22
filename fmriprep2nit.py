#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Dec 21 11:55:12 2018

@author: ltetrel
"""
import os
import re
import shutil
import json
import subprocess
import gzip
import numpy as np
import nibabel as nib

class Data2Bids():

    def __init__(self, input_dir="/nit", config=None, output_dir=None):
        self._input_dir = None
        self._config_path = None
        self._config = None
        self._bids_dir = None
        self._bids_version = "1.1.1"
        self._dataset_name = None

        self.set_data_dir(input_dir)
        self.set_config_path(config)
        self.set_bids_dir(output_dir)

    def set_data_dir(self, data_dir):
        if data_dir is None:
            self._data_dir = os.getcwd()
        else:
            self._data_dir = data_dir

        self._dataset_name = os.path.basename(self._data_dir)

    def _set_config(self):
        with open(self._config_path, 'r') as fst:
            data = fst.read()
            try:
                self._config = json.loads(data)
            except json.JSONDecodeError as exc:
                if exc.msg == 'Invalid \\escape':
                    data = data[:exc.pos] + '\\' + data[exc.pos:]
                    self._config = json.loads(data)
                else:
                    raise

    def set_config(self, config):
        self._config = config

    def set_config_path(self, config_path):
        if config_path is None:
            # Checking if a config.json is present
            if os.path.isfile(os.path.join(os.getcwd(), "config.json")):
                self._config_path = os.path.join(os.getcwd(), "config.json")
        else:
            self._config_path = config_path
        
        assert self._config_path is not None, "Please provide config file"
        self._set_config()

    def set_bids_dir(self, bids_dir):
        if bids_dir is None:
            # Creating a new directory for BIDS
            try:
                self._bids_dir = os.path.join(self._data_dir, self._dataset_name + "_Input")
            except TypeError:
                print("Error: Please provice input data directory if no BIDS directory...")
        else:
            self._bids_dir = bids_dir

    def match_regexp(self, config_regexp, filename, subtype=False):
        delimiter_left = config_regexp["left"]
        delimiter_right = config_regexp["right"]
        match_found = False

        if subtype:
            for to_match in config_regexp["content"]:
                if re.match(".*?"
                            #+ delimiter_left
                            +'sub-'
                            + '(' + to_match[1] + ')'
                            + delimiter_right
                            + ".*?", filename):
                    match = to_match[0]
                    match_found = True
        else:
            for to_match in config_regexp["content"]:
                if re.match(".*?"
                            #+ delimiter_left
                            +'sub-'
                            + '(' + to_match + ')'
                            + delimiter_right
                            + ".*?", filename):
                    match = re.match(".*?"
                                     #+ delimiter_left
                                     + '(' + to_match + ')'
                                     + delimiter_right
                                     + ".*?", filename).group(1)
                    match_found = True

        assert match_found
        return match

              
    def copy_NIfTI(self, src_file_path, dst_file_path, new_name):
        shutil.copy(src_file_path, dst_file_path + new_name + ".nii")
        #compression just if .nii files
        if self._config["compress"] is False:
            with open(dst_file_path + new_name + ".nii", 'rb') as f_in:
                with gzip.open(dst_file_path + new_name + ".nii.gz", 'wb') as f_out:
                    shutil.copyfileobj(f_in, f_out)
            os.remove(dst_file_path + new_name + ".nii")
    
    def maybe_create_BIDS_dir(self):
        if os.path.exists(self._bids_dir):
            shutil.rmtree(self._bids_dir)
        os.makedirs(self._bids_dir)
    
    def run(self):
        # First we check that every parameters are configured
        if (self._data_dir is not None
                and self._config_path is not None
                and self._config is not None
                and self._bids_dir is not None):

            print("---- fmriprep2FCD starting ----")
            print(self._data_dir)
            #print("\n BIDS version:")
            #print(self._bids_version)
            print("\n Config from file :")
            print(self._config_path)
            print("\n Ouptut FCD directory:")
            print(self._bids_dir)
            print("\n")

            # Maybe create the output BIDS directory
            self.maybe_create_BIDS_dir()

            #dataset_description.json must be included in the folder root foolowing BIDS specs
            #self.description_dump()

            # now we can scan all files and rearrange them
            for root, _, files in os.walk(self._data_dir):
                for file in files:
                    src_file_path = os.path.join(root, file)
                    dst_file_path = self._bids_dir

                    part_match = None
                    sess_match = None
                    data_type_match = None
                    run_match = None
                    new_name = None

                    # if the file doesn't match the extension, we skip it
                    if not re.match(".*?" + self._config["dataFormat"], file):
                        print("Warning : Skipping %s" %src_file_path)
                        continue

                    # Matching the participant label                   
                    try:
                        part_match = self.match_regexp(self._config["partLabel"], file)
                        dst_file_path = dst_file_path + "/sub-" + part_match
                        new_name = "/sub-" + part_match
                    except AssertionError:
                        print("No participant found for %s" %src_file_path)
                        continue

                    # Adding the modality to the new filename
                    #new_name = new_name + "_" + data_type_match

                    # Creating the directory where to store the new file
                    if not os.path.exists(dst_file_path):
                        os.makedirs(dst_file_path)

                    self.copy_NIfTI(src_file_path, dst_file_path, new_name)
                    
        else:
            print("Warning: No parameters are defined !")

import argparse

def get_parser():
    parser = argparse.ArgumentParser(
            formatter_class=argparse.RawDescriptionHelpFormatter
            , description=""
            , epilog="""
            Documentation at https://github.com/SIMEXP/Data2Bids
            """)

    parser.add_argument(
            "-d"
            , "--input_dir"
            , required=False
            , default= None
            , help="Input data directory(ies), Default: current directory",
            )

    parser.add_argument(
            "-c"
            , "--config"
            , required=False
            , default=None
            , help="JSON configuration file (see example/config.json)",
            )

    parser.add_argument(
            "-o"
            , "--output_dir"
            , required=False
            , default=None
            , help="Output BIDS directory, Default: Inside current directory ",
            )

    return parser

def main():
    args = get_parser().parse_args()
    data2bids = Data2Bids(**vars(args))
    Data2Bids().run()
    
if __name__ == '__main__':
    main()
