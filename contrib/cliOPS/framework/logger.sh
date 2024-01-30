#!/bin/bash

cliOps_LOGGER=$(printf '%s/%s_%s.log' "$cliOps_TMP_DIR" "logger" $cliOps_SESSION_ID)

function logFunction()
{
   echo -e "\n $1(func init)->" >> "$cliOps_LOGGER"
}

function log()
{   
   echo "[=[ LOG ]=] [ $1 ]->" >> "$cliOps_LOGGER"
}

function logError()
{   
   echo "[=[ ERROR ]=] $1 ]->" >> "$cliOps_LOGGER"
}

function logInfo()
{   
   echo "[=[ INFO ]=] $1 ]->" >> "$cliOps_LOGGER"
}

function logReader()
{
   echo $(cat "$cliOps_LOGGER" | tr '\n' '  ')
}

function logExtractor()
{
   local LOG
   # if in settings.yml log is disable
   case $(cliOps_SETTINGS_LOGGING_VERBOSITY_GET) in
   all)      
      LOG=$(logReader)
   ;;   
   log)      
      LOG=$(awk -F'\\[=\\[ LOG \\]=\\]\\s*' '{for (i=2; i<=NF; i+=2) {gsub(/\]->.*/, "-=-", $i); print $i}}' $cliOps_LOGGER 2>&1 /dev/null)
   ;;   
   info)      
      LOG=$(awk -F'\\[=\\[ INFO \\]=\\]\\s*' '{for (i=2; i<=NF; i+=2) {gsub(/\]->.*/, "-=-", $i); print $i}}' $cliOps_LOGGER 2>&1 /dev/null)
   ;;  
   error)      
      LOG=$(awk -F'\\[=\\[ ERROR \\]=\\]\\s*' '{for (i=2; i<=NF; i+=2) {gsub(/\]->.*/, "-=-", $i); print $i}}' $cliOps_LOGGER 2>&1 /dev/null)
   ;;
   *)
      LOG='Check _contrib/tmp folder for logs'
   ;;
   esac      

   echo $LOG
}
