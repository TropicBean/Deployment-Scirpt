#!/bin/bash


cd /shares/mmp/fbp/masrc

arrEnvs=("/shares/mmp/fbp" "/shares/mmp/fbk" "/shares/mmp/prf" "/shares/mmp/key")

for env in ${arrEnvs[@]}
do
  find $env"/masrc/"  -type f | while read file
  do

    echo $(basename $file)
  
    fileExtension=".${file##*.}"
  
    rcodedir=$env"/run/"$(dirname $(realpath --relative-to=/shares/mmp/fbp/masrc $file)) 
    rcodefilename=$(basename $file $fileExtension)".r"

    echo $rcodedir
    echo $rcodefilename
    
    mkdir -p $rcodedir
    
    cd $rcodedir
     
    touch $rcodefilename
 
  done  # find $env/masrc
done # for env in   