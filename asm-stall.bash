#!/bin/bash
# vim: sw=4 ts=4
########################################################################
#						 Wait Until ASMLIB Disks Appear
########################################################################
# Give time for SAN devices to stabilize and be detected before we allow
# the system to progress further.
#
# Run it like this:
# /usr/local/bin/asm-stall ASM1 ASM2 ASM...
# or
# /usr/local/bin/asm-stall -f /usr/local/etc/asmlib-disks
#
# -f file		Read list of ASM disks from 'file', one per line
# -r retries	Try up to 'retries' times (default=20) before abandoning
# -t seconds	After each try, wait 'seconds' (default=30)
########################################################################

timestamp()	{
	/bin/date '+%Y-%m-%dT%H:%M:%S'
}

########################################################################
ME=`/bin/basename $0`
USAGE="usage: ${ME} [-f file] [-r RETRIES] [-t seconds] [LABEL1..]"
TIMEOUT=30
LOGFILE=/var/log/oracleasm
RETRIES=20
DISKS=
FROMFILE=
while getopts f:r:t: c; do
	case "${c}" in
	f )	FROMFILE="${OPTARG}";;
	r ) RETRIES="${OPTARG}";;
	t ) TIMEOUT="${OPTARG}";;
	* )	echo "${USAGE}" >&2; exit 1;;
	esac
done;
shift `/usr/bin/expr ${OPTIND} - 1`
if [ "${FROMFILE}" ]; then
	cat "${FROMFILE}" | while read line; do
		echo "line=${line}"
		line=`echo "${line}" | /bin/sed -e 's/\#.*$//' | /usr/bin/tr '[\n]' ' '`
		DISKS="${DISKS} ${line}"
		echo "DISKS=${DISKS}"
	done
fi
if [ $# -gt 0 ]; then
	DISKS="${DISKS} $@"
fi
echo "$(timestamp) Beginning ASMLIB scan for [${DISKS} ]" >>${LOGFILE}
for disk in ${DISKS}; do
	bdev="/dev/oracleasm/disks/${disk}"
	while [ ! -b ${bdev} ]; do
		if [ ${RETRIES} -le 0 ]; then
			/usr/bin/logger "oracleasm out of patience; abandoning '${disk}'."
			break
		fi
		/usr/bin/logger -p local0.debug "Waiting for ${bdev}"
		sleep ${TIMEOUT}
		/usr/bin/logger -p local0.debug "scandisks looking for ${disk}"
		/usr/sbin/oracleasm scandisks
		/usr/sbin/oracleasm listdisks
		RETRIES=`/usr/bin/expr ${RETRIES} - 1`
	done
	if [ -b ${bdev} ]; then
		FOUND="${FOUND} ${disk}"
	else
		/usr/bin/logger "oracleasm disk '${disk}' not found initially."
	fi
	RETRIES=$(($RETRIES-1))
done
if [ ${RETRIES} -eq 0 ]; then
	/usr/bin/logger -p local0.alert "ERROR -- could not find all ASM disks"
fi
echo "$(timestamp) Discovered ASMLIB disk inventory [${FOUND} ]" >>${LOGFILE}
