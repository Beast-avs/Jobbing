#!/bin/bash

[[ "$1" == "" ]] && classname=`echo $0 | sed "s/test_//g;s/\.sh//g"` || classname=`echo $1 | sed "s/.\/src\///g" | sed "s/.java//g"`

currentdir=`dirname $0`
currentdate=`date +'%Y%m%d%H%M%S'`

# Set some environment variables
export CLASSPATH=${currentdir}/lib/log4j.jar:${currentdir}/lib/commons-cli-1.2.jar
export CSCONFIGDIR=.

echo "compiling ...."
javac -cp $CLASSPATH ./src/$classname.java -d ./

echo "executing ...."

# Add addition libs into CLASSPATH
applibdir=/path_to_aaplib/
libs_a=$( echo $applibdir/pattern1*.jar  | sed 's/ /:/g' )
libs_b=$( echo $applibdir/pattern2*.jar  | sed 's/ /:/g' )

# Get the line number of the SERVICE log for obtaining the begin of the CS-API call
node_1_start=`wc -l /path_to_service/node_1/log/SEVICELOG | awk '{print $1}'`
node_2_start=`wc -l /path_to_service/node_2/log/SEVICELOG | awk '{print $1}'`

# Run JAVA with parameters from CLI andtransmit them into JAVA-class. 
# All events which come throug STDOUT and STDERR send to logfile
java -cp ${currentdir}:${CLASSPATH}:${libs_a}:${libs_b} $classname "$@" 2>&1 | /usr/local/bin/tee -a ${currentdir}/logs/$classname--out--$currentdate.log

# Get the line number of the BAS log for obtaining the end of the CS-API call
node_1_end=`wc -l /path_to_service/node_1/log/SEVICELOG | awk '{print $1}'`
node_2_end=`wc -l /path_to_service/node_2/log/SEVICELOG | awk '{print $1}'`

# Get logs from BAS Node 01
sed -n "${node_1_start},${node_1_end}p" /path_to_service/node_1/log/SEVICELOG > "${currentdir}/logs/$classname--bas_01_01--$currentdate.log"

# Get logs from BAS Node 02
sed -n "${node_1_start2},${node_2_end}p" /path_to_service/node_2/log/SEVICELOG > "${currentdir}/logs/$classname--bas_01_02--$currentdate.log"

# This is not needed but left here just for case
## Removing the class-file
#echo "removing $classname.class ...."
#rm -f $classname.class
#echo "done."