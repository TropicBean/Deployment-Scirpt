#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Create ProgressBar function
# 1.1 Input is currentState($1) and totalState($2)
function ProgressBar {
# Process data
    let _progress=(${1}*100/${2}*100)/100
    let _done=(${_progress}*4)/10
    let _left=40-$_done
# Build progressbar string lengths
    _fill=$(printf "%${_done}s")
    _empty=$(printf "%${_left}s")

# 1.2 Build progressbar strings and print the ProgressBar line
# 1.2.1 Output example:                           
# 1.2.1.1 Progress : [########################################] 100%
printf "\rProgress : [${_fill// /#}${_empty// /-}] ${_progress}%%"

}

function ProgressionState {
	# Variables
	let _start=${1}

	# This accounts as the "totalState" variable for the ProgressBar function
	let _end=${2}

	for ((number = ${_start} ; number <= ${_end} ; number = number + 10))
	do
	    sleep 0.03
	    ProgressBar $number 100	
	done
}



if [ ! -d "/shares/wip/mmp/deploy" ]
then
 
 echo "To use this script , make sure a /shares/wip/mmp/deploy directory exists and the code you want to deploy exists within this directory" 
 
 exit 2 
 
 
fi


mkdir -p /shares/wrk117/
mkdir -p /shares/wip/mmp/backup

cDeployFromDir="/shares/wip/mmp/deploy"
cBackupDir="/shares/wip/mmp/backup"

read -p "Deploying from $cDeployFromDir"
read -p "Backups will be stored in $cBackupDir"

read -p "This script will deploy to all the mmp environments(fbp,fbk,prf,key) . Press (D) to deploy a file and (S) to skip"  cPrompt


find "$cDeployFromDir" \( -name "*.p" -o -name "*.cls" -o -name "*.w" \) -type f  > "$cDeployFromDir/filestodeploy.txt"

#Create a file to log all the files that have actually been deployed by the dev during the process
echo "" > "$cDeployFromDir/deployedfiles.txt"
#Create a fild in which we will store all the files names that have been backed up during deplpoyment
echo "" > "$cDeployFromDir/backupfiles.txt"

#This array will contain all the environments this script will deploy to
arrDeploymentEnvs=("/shares/mmp/fbp/masrc") #"/shares/mmp/fbk/masrc" "/shares/mmp/prf/masrc" "/shares/mmp/key/masrc")


while read file
do
  echo ""
  echo "$file (D/S) "
  
  while true
  do
   
    read -u 1 -n 1 -r -s cKey
    
    if [[ "$cKey" == "s" || "$cKey" == "d" ]]
    then
      break
    fi
  done
  
  if [[ $cKey == "d" ]]
  then 

     echo "Deploying file" 
     
     ProgressionState "0" "20"
     
      
     for env in ${arrDeploymentEnvs[@]}
     do

       # skip the env if it has any funky input 
       if [[ $env == "" && $env == "/" && $env == "/shares" && $env == "*" ]]
       then  
         continue
       fi 
       

       # Now let's try to find the file we are going to replace in the deployment environment 
       find "$env" -name "$(basename $file)" -type f | while read envfile
       do
         
         if [[ $envfile != ""  ]]
         then
         	
    
	   #First make a backup of the old file before we replace it 
           cDirname="$(dirname "$(realpath --relative-to=/shares/mmp $env)")/""$(dirname "$(realpath --relative-to=$env $envfile)")"
         
          # echo "making dir $cBackupDir/$cDirname " 
   	   mkdir -p "$cBackupDir/$cDirname"
         
           cp "$envfile" "$cBackupDir/$cDirname"
           
           #Now replace the file 
           cp "$file" "$(dirname $envfile)"            

          
	   echo "$file" >> "$cDeployFromDir/deployedfiles.txt" 
         fi 
       
       done
     done     
     
     
     ProgressionState "20" "100" 
     
     echo
  else
     echo "Skipped"
 
  fi
done < "$cDeployFromDir/filestodeploy.txt"

#At this stage , the .p,.w and .cls files would have been replaced. We now need to find the corresponding .r files and remove them as well 

echo
echo "Deployment done , would you like to remove old r-code for the deployed files(Recommended) y/n"
  
while true
do
   
  read -u 1 -n 1 -r -s cKey
    
  if [[ "$cKey" == "y" || "$cKey" == "n" ]]
  then
    break
  fi
  
done

if [[ "$cKey" == "y" ]]
then

 echo "" > "$cDeployFromDir/rcoderemovalreport.txt"
 
 arrRunDirectories=("/shares/mmp/fbp/run" ) #"/shares/mmp/fbk/run") 
 
 for env in ${arrRunDirectories[@]}
 do
 
   cEnvironmentRunDirectory=$env
   
   while read file 
   do
   	
    if [[ $file = "" ]] 
    then 
      continue ;
    fi 
   
    fileExtension=".${file##*.}"
  
    cFileToDelete="$(basename $file $fileExtension).r" 
   # echo $cEnvironmentRunDirectory
   # echo $cFileToDelete
    echo "Searching for file $cFileToDelete" >> "$cDeployFromDir/rcoderemovalreport.txt"
    find "$cEnvironmentRunDirectory" -name "$cFileToDelete" -type f | while read rcodefile
    do
     
      if [ "$rcodefile" != "" -a "$rcodefile" !=  " " -a "$rcodefile" != *"*"*  ]; then    
      
        echo "deleting $rcodefile " | tee -a "$cDeployFromDir/rcoderemovalreport.txt"
        rm "$rcodefile"
      
        #If were working with a class file there might be a parent class that also needs to be removed
        if [ "$fileExtension" = ".cls" ]; then 
          cParentClass=${rcodefile#*base}
          echo "Searching for parent class $cParentClass ..." >> "$cDeployFromDir/rcoderemovalreport.txt"
        
          find "$cEnvironmentRunDirectory" -name "$cParentClass" -type f | while read parentclassfile
          do
            echo "deleting $parentclassfile "  | tee -a "$cDeployFromDir/rcoderemovalreport.txt"
            rm "$parentclassfile" 
          done
        
        fi
      fi
    done   
  done < "$cDeployFromDir/deployedfiles.txt"
  
  echo "Old R-code removed"
  echo  
done 
  
fi

echo
echo "Would you like to restart the brokers? y/n" 

while true
do
   
  read -u 1 -n 1 -r -s cKey
    
  if [[ "$cKey" == "y" || "$cKey" == "n" ]]
  then
    break
  fi
  
done

if [[ $cKey == "y" ]]
then
  

  echo "Restarting fbp ..." 
  
  #mmpfbp pro-shbrk wsb wsb_mmpfbp
  touch /shares/wrk117/wsb_mmpfbp.server.log
  echo "Failed" > /shares/wrk117/wsb_mmpfbp.server.log
  
  sleep 3s
  #mmpfbp pro-stbrk wsb wsb_mmpfbp
  
  if grep -q "Ready to accept requests" /shares/wrk117/wsb_mmpfbp.server.log ;
  then
    echo -e "${GREEN}SUCCESS ${NC}"
  else
    echo -e "${RED}FAILED ${NC}"
    
  echo
  echo "The broker could not be started , which means there could be a problem with the source that has just been deployed ,would you like to revert to the last working version? y/n"
     
  while true
  do
   
    read -u 1 -n 1 -r -s cKey
    
    if [[ "$cKey" == "y" || "$cKey" == "n" ]]
    then
      break
    fi
  done
  
  #if [[ $cKey == "y" ]] 
  #then
    
    
  
 # fi
   
 fi
  
  echo "Restarting fbk ..." 
  #mmpfbk pro-shbrk wsb wsb_mmpfbk
  #sleep 3s
  #mmpfbk pro-stbrk wsb wsb_mmpfbk
  
  #if grep -q "Ready to accept requests" /shares/wrk117/wsb_mmpfbk.server.log ;
  #then
  #  echo -e "${GREEN}SUCCESS ${NC}"
 # else
 #   echo -e "${RED}FAILED ${NC}"
   
 # fi
        
fi

echo 
echo