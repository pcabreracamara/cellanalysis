#!/bin/bash

######################################################################
#	FakeBTS.com
#	2014
#	v 0.1.6
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

# RUTAS de BINARIOS OSMOCOM
CELLBIN="/opt/osmocom-bb/src/host/layer23/src/misc/cell_log"
CCCHBIN="/opt/osmocom-bb/src/host/layer23/src/misc/ccch_scan"
TSHARKBIN="/usr/local/bin/tshark"
# RUTA de FICHEROS DE SALIDA
SCRIPTDIR="$( cd "$( /usr/bin/dirname "$0" )" && pwd )"
# Variables
CELLVER=""

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
if [ ! -f "${CELLBIN}" ]
then
        echo "Exit !!, ${CELLBIN} no existe."
        exit 0
fi

if [ ! -f "${CCCHBIN}" ]
then
        echo "Exit !!, ${CCCHBIN} no existe."
        exit 0
fi

if [ ! -f "${TSHARKBIN}" ]
then
        echo "Exit !!, ${TSHARKBIN} no existe."
        exit 0
fi

# Detectamos version de cell_log
"${CELLBIN}" --help| grep "\-\-wait-time" > /dev/null 2>&1
if [ $? -eq 1 ]
then
	CELLVER="new"
else
	CELLVER="old"
fi

echo "Leyendo celdas cercanas ..."
case $CELLVER in
"old") "${CELLBIN}" -s /tmp/osmocom_l2 -O -w 120 -G > /tmp/out_cell_log.txt 2>&1 &;;
"new") "${CELLBIN}" -s /tmp/osmocom_l2  > /tmp/out_cell_log.txt 2>&1 &;;
*) "${CELLBIN}" -s /tmp/osmocom_l2  > /tmp/out_cell_log.txt 2>&1 &;;
esac

# Dejamos tiempo de espera al proceso de busqueda de celdas, si no ha acabado lo matamos
sleep 50
grep exit /tmp/out_cell_log.txt 2>&1
if [ $? -eq 1 ]
then
	disown
	kill -9 $!
fi

# Chequeamos que hemos detectado al menos una celda
if [ `grep Cell: /tmp/out_cell_log.txt | wc -l` -gt 0 ]
then

	if [ $CELLVER = "old" ]
	then
		cat /tmp/out_cell_log.txt | awk '{if($2=="ID:"){id=$3;getline;printf "%s;%s;%s;%s;%s\n", $2, $4, $5, $6, $7}}' | sed 's/ARFCN=//g' | sed 's/PWR=//g'| sed 's/dB//g' | sed 's/MCC=//g' | sed 's/MNC=//g' | awk -F";" '{ if( $3 >= -70 ){print $0}}' > /tmp/arfcn_list.txt
	else
		cat /tmp/out_cell_log.txt | awk '{if($3=="Cell:"){printf "%s;%s;%s;%s;%s\n", $4, $5, $6, $7, $8 }}' | sed 's/ARFCN=//g' | sed 's/MCC=//g' | sed 's/MNC=//g' > /tmp/arfcn_list.txt
	fi

	cat /tmp/arfcn_list.txt | while read linea
	do

		arfcn=`echo "${linea}" | cut -d";" -f1`
		mcc=`echo "${linea}" | cut -d";" -f2`
		mnc=`echo "${linea}" | cut -d";" -f3`
		hora=`date +"%H:%M"`
		num_chan=0

		"${TSHARKBIN}" -i lo -a duration:10 -w /tmp/tshark_${arfcn}.pcap > /dev/null 2>&1 &
		echo "Procesando canal: ${arfcn}"
		"${CCCHBIN}" -s /tmp/osmocom_l2 -a ${arfcn} -i 127.0.0.1 > /tmp/ccch_${arfcn}_${hora}.txt 2>&1 &
		sleep 20
		disown
		kill -9 $!

		# Para algunas ramas de GIT necesitamos ignorar ciertas medidas
		num_lin=`wc -l /tmp/ccch_${arfcn}_${hora}.txt | awk '{print $1}'`
		umbral=`echo $[$num_lin/2]`
		umbral_fb=`echo "$num_lin / 1.55"| bc`
		umbral_subs=`echo $[$num_lin * 0,2]`

		# Numero de abonados encontrados en la celda
		grep "MSI" /tmp/ccch_${arfcn}_${hora}.txt > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
			num_subs=`grep -i MSI /tmp/ccch_${arfcn}_${hora}.txt| wc -l`
		else
			num_subs=0
		fi

		# Numero de canales y valor de elllos en la celda
		"${TSHARKBIN}" -r /tmp/tshark_${arfcn}.pcap -c 1 -T pdml -2 -R "gsm_a.dtap.msg_rr_type == 0x19" > /tmp/tshark_${arfcn}.txt 2>&1
		grep "List" /tmp/tshark_${arfcn}.txt > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
			num_chan=`cat /tmp/tshark_${arfcn}.txt |grep "List"| awk -F"\"" '{print $4}'| cut -d= -f2| awk '{print NF}'`
			if [ ${num_chan} -eq 1 ]
                	then
                        	channel=`cat /tmp/tshark_${arfcn}.txt | grep "List"| awk -F"\"" '{print $4}'| cut -d= -f2`
                	fi
		else
			num_chan=0
			channel=666
		fi

		# Buscamos el CellID y LAC
		"${TSHARKBIN}" -r /tmp/tshark_${arfcn}.pcap -c 1 -T pdml -2 -R "gsm_a.dtap.msg_rr_type == 0x1b" > /tmp/tshark_${arfcn}.txt 2>&1
		grep "Cell CI" /tmp/tshark_${arfcn}.txt > /dev/null 2>&1
                if [ $? -eq 0 ]
                then
			cellid=`cat /tmp/tshark_${arfcn}.txt |grep "Cell CI" | awk -F"showname=" '{print $2}'| cut -d"\"" -f2|awk '{print $3}'| sed 's/0x//'`
			lac=`cat /tmp/tshark_${arfcn}.txt |grep "LAC" | awk -F"showname=" '{print $2}'| cut -d"\"" -f2|awk '{print $5}'| sed 's/0x//'`
		else
			cellid=0
			lac=0
		fi

		#rm /tmp/tshark_${arfcn}.pcap
		#rm /tmp/tshark_${arfcn}.txt


		# Errores a tener en cuenta
		num_burst=`grep BURST /tmp/ccch_${arfcn}_${hora}.txt | wc -l`
		num_drop=`grep Dropping /tmp/ccch_${arfcn}_${hora}.txt | wc -l`
		num_fbsb=`grep FBSB /tmp/ccch_${arfcn}_${hora}.txt | wc -l`
	
		errors=`echo $[$num_burst + $num_drop + $num_fbsb]`

		operador=`echo "${linea}" | awk -F";" '{print $4,$5}'`

		if [ ${num_burst} -lt ${umbral} ] && [ ${num_drop} -lt ${umbral} ]  && [ ${num_fbsb} -lt ${umbral_fb} ]
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
			echo "Se ignoran las medidas del canal ${arfcn}. Errores de DROP: ${num_drop}, BURST IND: ${num_burst}, FBSB: ${num_fbsb}"
			echo "${hora};${lac}-${cellid};${arfcn};${mcc};${mnc};${operador};${num_subs};${num_chan};${num_burst};${num_drop};${num_fbsb}" >> ${SCRIPTDIR}/ignore.csv
		fi

	done

	echo "Terminado"

else
	hora=`date +"%d/%m %H:%M"`
	echo "Error, no se han encontrado celdas"
	echo "${hora} No se han encontrado celdas" >> ${SCRIPTDIR}/error.log
fi
