#!/bin/bash
#
# Script to check MegaRaidCLI Failed drives
# Works on servers with ONE RAID controller
#
# Example:
#   CRIT - Virtual Drives: {Degraded: 0, Offline: 2}, Physical Disks: {Critical: 0, Failed: 2}, 
#   Bad Drives: [{adapter: 0, enclID: 2, slot: 7, Span ref: 8, Row: 0}, {adapter: 0, enclID: 2, slot: 1, Span ref: 2, Row: 0}]

if [[ -x /opt/MegaRAID/MegaCli/MegaCli64 ]]; then
  megaraid_bin="sudo /opt/MegaRAID/MegaCli/MegaCli64"
elif [[ -x /opt/MegaRAID/MegaCli/MegaCli ]]; then
  megaraid_bin="sudo /opt/MegaRAID/MegaCli/MegaCli"
else
  echo "ERROR. No such MegaCli command"
  exit 1
fi

anyissue=$(${megaraid_bin} -AdpAllInfo -aAll | grep -E 'Degrade|[[:space:]][[:space:]]Failed|[[:space:]][[:space:]]Offline' | awk '/[1-9]/ {print $0}' | wc -l)

degrade=$(${megaraid_bin} -AdpAllInfo -aAll | grep -E 'Degrade' | awk '/[0-9]/ {print $3}')
critical=$(${megaraid_bin} -AdpAllInfo -aAll | grep -E 'Critical' | awk '/[0-9]/ {print $4}')
offline=$(${megaraid_bin} -AdpAllInfo -aAll | grep -E '[[:space:]][[:space:]]Offline' | awk '/[0-9]/ {print $3}')
failed=$(${megaraid_bin} -AdpAllInfo -aAll | grep -E '[[:space:]][[:space:]]Failed' | awk '/[0-9]/ {print $4}')

if [[ ${anyissue} -ge 1 ]]; then
  ${megaraid_bin} -CfgDsply -aALL > /tmp/Cfgdsply.txt
  failed_lines=$(grep -n "Failed" /tmp/Cfgdsply.txt | cut -d':' -f1)
 
  for failed_line in ${failed_lines}; do
    sed -n "1,${failed_line}p" /tmp/Cfgdsply.txt > /tmp/Cfgdsply_tofailed.txt
    tac /tmp/Cfgdsply_tofailed.txt > /tmp/backw_Cfgdsply.txt
 
    fadpt=$(grep -m 1 "Adapter" /tmp/backw_Cfgdsply.txt | cut -d':' -f2 | sed -e "s/ //g")
    enclID=$(grep -m 1 "Enclosure Device ID" /tmp/backw_Cfgdsply.txt | cut -d':' -f2 | sed -e "s/ //g")
    slot=$(grep -m 1 "Slot Number" /tmp/backw_Cfgdsply.txt | cut -d':' -f2 | sed -e "s/ //g")
    spanref=$(grep -m 1 "Span Reference" /tmp/backw_Cfgdsply.txt | cut -d':' -f2 | sed -e "s/ //g" | cut -d'x' -f2 | cut -c 2)
    row=$(grep -m 1 "Physical Disk:" /tmp/backw_Cfgdsply.txt | cut -d':' -f2 | sed -e "s/ //g")
 
    if [[ -z "${bad_drives_info}" ]]; then
      bad_drives_info="{adapter: "${fadpt}", enclID: "${enclID}", slot: "${slot}", Span ref: "${spanref}", Row: "${row}"}"
    else
      bad_drives_info="{adapter: "${fadpt}", enclID: "${enclID}", slot: "${slot}", Span ref: "${spanref}", Row: "${row}"}, ${bad_drives_info}"
    fi
  done
 
  echo "CRIT. Virtual Drives: {Degraded: "${degrade}", Offline: "${offline}"}, Physical Disks: {Critical: "${critical}", Failed: "${failed}"}, Bad Drives: [${bad_drives_info}]"
 
  # clean up temp files
  rm -f /tmp/Cfgdsply.txt
  rm -f /tmp/Cfgdsply_tofailed.txt
  rm -f /tmp/backw_Cfgdsply.txt
  rm -f MegaSAS.log*
  rm -f CmdTool.log*
 
  exit 2
else
  if [[ -z "${degrade}" ]] || [[ -z "${critical}" ]] || [[ -z "${offline}" ]] || [[ -z "${failed}" ]]; then
    echo "OK. No disk issue"
  else
    echo "OK. No disk issue. Virtual Drives: { Degraded: "${degrade}", Offline: "${offline}" }, Physical Disks: {Failed: "${failed}"}"
  fi
 
  # clean up temp files
  rm -f MegaSAS.log*
  rm -f CmdTool.log*
 
  exit 0
fi
