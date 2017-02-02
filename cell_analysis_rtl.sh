#!/bin/bash

######################################################################
#       FakeBTS.com
#       2014
#       v 0.1.6
#######################################################################
#
#   Copyright (C) 2014 Pedro Cabrera
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
#    Contact Info:
#    @PCabreraCamara
#    pedrocab@gmail.com
#
#######################################################################

# Variables
KALBIN="/usr/bin/kal"
GSMRECPATH="/opt/airprobe/gsm-receiver/src/python/"
TSHARKBIN="/usr/bin/tshark"
# GSM900:	Banda de los 900Mhz
# DSC:		Banda de los 1800Mhz
#BANDAS="GSM900 DCS"
BANDAS=GSM900
# RUTA de FICHEROS DE SALIDA
SCRIPTDIR="$( cd "$( /usr/bin/dirname "$0" )" && pwd )"
# X11 Display (airprobe)
DISPLAY=:0.0
export DISPLAY

# Licencia

function disclaimer {
        echo "CellAnalysis  Copyright (C) 2014 Pedro Cabrera"
        echo "This program comes with ABSOLUTELY NO WARRANTY; for details visit http://www.gnu.org/licenses/gpl.txt"
        echo "This is free software, and you are welcome to redistribute it"
        echo "under certain conditions; for details visit http://www.gnu.org/licenses/gpl.txt."
        echo
}

disclaimer

# Comprobamos que existen los binarios
if [ ! -f "${KALBIN}" ]
then
	echo "Exit !!, ${KALBIN} no existe."
	exit 0
fi

if [ ! -f "${GSMRECPATH}gsm_receive_rtl.py" ]
then
        echo "Exit !!, ${GSMRECPATH}gsm_receive_rtl.py no existe."
        exit 0
fi

if [ ! -f "${TSHARKBIN}" ]
then
        echo "Exit !!, ${TSHARKBIN} no existe."
        exit 0
fi

echo "Leyendo celdas cercanas ..."
echo > /tmp/out_kal.txt
for band in ${BANDAS}
do
	${KALBIN} -s ${band} &>> /tmp/out_kal.txt
done

grep "chan:" /tmp/out_kal.txt > /dev/null 2>&1

if [ $? -eq 0 ]
then

	grep "chan:" /tmp/out_kal.txt | while read linea
	do
		arfcn=`echo "${linea}" | awk '{print $2}'`
		freq_tmp=`echo "${linea}" | awk '{print $3}' | sed 's/(//g'| sed 's/MHz//g' | sed 's/\.//g'`
		freq_base=`echo ${freq_tmp}00000`
		signo=`echo "${linea}" | awk '{print $4}'`
		offset=`echo "${linea}" | awk '{print $5}' | sed 's/)//g'| sed 's/kHz//g' | sed 's/\.//g'`
		freq_final=`echo $[${freq_base} ${signo} ${offset}]`
		num_chan=0

		"${TSHARKBIN}" -i lo -a duration:10 -w /tmp/tshark_${arfcn}.pcap > /dev/null 2>&1 &
		echo "Procesando canal: ${arfcn}"
		cd ${GSMRECPATH} > /dev/null 2>&1
		./gsm_receive_rtl.py -s 1e6 -f ${freq_final} -g 42 > /dev/null 2>&1 &
		sleep 20
		disown
		kill -9 $! > /dev/null
		cd - > /dev/null 2>&1

		# Numero de abonados
                "${TSHARKBIN}" -r /tmp/tshark_${arfcn}.pcap -T pdml -2 -R "gsm_a.dtap.msg_rr_type == 0x21" > /tmp/tshark_subs_${arfcn}.txt 2>&1
		grep "MSI" /tmp/tshark_subs_${arfcn}.txt > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			num_subs=`grep MSI /tmp/tshark_subs_${arfcn}.txt| wc -l`
		else
			num_subs=0
		fi

		# Numero de frames CCCH capturados
		"${TSHARKBIN}" -z io,phs -r /tmp/tshark_${arfcn}.pcap > /tmp/num_frames_${arfcn}.txt 2>&1
		grep ccch /tmp/num_frames_${arfcn}.txt > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
			num_lin=`grep ccch /tmp/num_frames_${arfcn}.txt | awk -F"frames:" '{print $2}'| cut -d" " -f1`
		else
			num_lin=0
		fi
		#rm /tmp/num_frames_${arfcn}.txt

                umbral=6
                umbral_subs=`echo $[$num_lin * 0,2]`

		# Numero de canales y valor de elllos en la celda
                "${TSHARKBIN}" -r /tmp/tshark_${arfcn}.pcap -c 1 -T pdml -2 -R "gsm_a.dtap.msg_rr_type == 0x19" > /tmp/tshark_canales_${arfcn}.txt 2>&1
		grep "List" /tmp/tshark_canales_${arfcn}.txt > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
	                num_chan=`cat /tmp/tshark_canales_${arfcn}.txt |grep "List"| awk -F"\"" '{print $4}'| cut -d= -f2| awk '{print NF}'`
       		        if [ ${num_chan} -eq 1 ]
			then
                       		channel=`cat /tmp/tshark_canales_${arfcn}.txt | grep "List"| awk -F"\"" '{print $4}'| cut -d= -f2`
                	fi
		else
			num_chan=0
			channel=666
		fi

               	# Buscamos el CellID y LAC
                "${TSHARKBIN}" -r /tmp/tshark_${arfcn}.pcap -c 1 -T pdml -2 -R "gsm_a.dtap.msg_rr_type == 0x1b" > /tmp/tshark_cellid_${arfcn}.txt 2>&1
		grep "Cell CI" /tmp/tshark_cellid_${arfcn}.txt > /dev/null 2>&1
		if [ $? -eq 0 ]
		then
                	cellid=`cat /tmp/tshark_cellid_${arfcn}.txt |grep "Cell CI" | awk -F"showname=" '{print $2}'| cut -d"\"" -f2|awk '{print $3}'| sed 's/0x//'`
                	lac=`cat /tmp/tshark_cellid_${arfcn}.txt |grep "LAC" | awk -F"showname=" '{print $2}'| cut -d"\"" -f2|awk '{print $5}'| sed 's/0x//'`
			mcc=`cat /tmp/tshark_cellid_${arfcn}.txt |grep "MCC"| awk -F"showname=" '{print $2}'| cut -d"\"" -f2|cut -d"(" -f3| sed 's/)//g'`
			mnc=`cat /tmp/tshark_cellid_${arfcn}.txt |grep "MNC"| awk -F"showname=" '{print $2}'| cut -d"\"" -f2|cut -d"(" -f3| sed 's/)//g'`
			operador=`cat /tmp/tshark_cellid_${arfcn}.txt |grep "MNC"| awk -F"showname=" '{print $2}'| cut -d"\"" -f2|cut -d":" -f2 | cut -d"(" -f1`
		else
			cellid=0
			lac=0
			mcc=0
			mnc=0
			operador=""
		fi
	
		rm /tmp/tshark_subs_${arfcn}.txt	
                rm /tmp/tshark_canales_${arfcn}.txt
		rm /tmp/tshark_cellid_${arfcn}.txt

		if [ ${num_lin} -ne 0 ]
                then
                        if [ ${num_chan} -eq 1 ] && [ ${num_subs} -lt ${umbral_subs} ]
                        then
                                hora=`date +"%d/%m %H:%M"`
				echo "Celda con 1 solo canal!!, Alarma en LAC: ${lac}, CellID: ${cellid}, arfcn: ${arfcn}"
                                echo "${hora};${lac}-${cellid};${arfcn};${mcc};${mnc};${operador};${num_subs};${num_chan}" >> ${SCRIPTDIR}/alarms.csv
			elif [ ${num_chan} -gt 1 ] && [ ${num_subs} -lt ${umbral_subs} ]
                        then
                                hora=`date +"%d/%m %H:%M"`
                                echo "Posible alarma en LAC: ${lac}, CellID: ${cellid}, arfcn: ${arfcn}"
                                echo "${hora};${lac}-${cellid};${arfcn};${mcc};${mnc};${operador};${num_subs};${num_chan}" >> ${SCRIPTDIR}/alarms.csv
                        else
                                hora=`date +"%d/%m %H:%M"`
				echo "Se escriben los datos de trafico al fichero: ${arfcn}.csv"
                                echo "${hora};${lac}-${cellid};${arfcn};${mcc};${mnc};${operador};${num_subs};${num_chan}" >> ${SCRIPTDIR}/${arfcn}.csv
                        fi
                else
                        hora=`date +"%d/%m %H:%M"`
			echo "Se ignoran las medidas del canal ${arfcn}."
                        echo "${hora};${lac}-${cellid};${arfcn};${mcc};${mnc};${operador};${num_subs};${num_chan};${num_burst};${num_drop};${num_fbsb}" >> ${SCRIPTDIR}/ignore.csv
                fi
	
	done	

	echo "Terminado"
else
        hora=`date +"%d/%m %H:%M"`
        echo "Error, no se han encontrado celdas"
        echo "${hora} No se han encontrado celdas" >> ${SCRIPTDIR}/error.log
fi
