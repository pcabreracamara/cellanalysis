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

# Licencia

function disclaimer {
        echo "CellAnalysis  Copyright (C) 2014 Pedro Cabrera"
        echo "This program comes with ABSOLUTELY NO WARRANTY; for details visit http://www.gnu.org/licenses/gpl.txt"
        echo "This is free software, and you are welcome to redistribute it"
        echo "under certain conditions; for details visit http://www.gnu.org/licenses/gpl.txt."
        echo
}

disclaimer

# Cuenta de correo
# Reemplazar por cuenta real si se dispone de postfix.
CONTACTO="root"
# RUTA de FICHEROS DE SALIDA
SCRIPTDIR="$( cd "$( /usr/bin/dirname "$0" )" && pwd )"

if [ -s ${SCRIPTDIR}/error.log ]
then
	num_err=`cat ${SCRIPTDIR}/error.log | wc -l`
	if [ ${num_err} -eq 2 ] && [ ! -f ${SCRIPTDIR}/error.mail ]
	then
		touch ${SCRIPTDIR}/error.mail
		echo "Se han producido ${num_err} errores." | mail -s "Multiples errores en cell_analysis" ${CONTACTO} 
	fi
fi

if [ -s ${SCRIPTDIR}/alarms.csv ]  && [ ! -f ${SCRIPTDIR}/error.mail ]
then
        num_alarms=`cat ${SCRIPTDIR}/alarms.csv | wc -l`
        if [ ${num_alarms} -ge 1 ]
        then
                cat ${SCRIPTDIR}/alarms.csv | mail -s "Alarmas encontradas en cell_analysis" ${CONTACTO} 
		hora=`date +"%d_%m_%H%M"`
		mv ${SCRIPTDIR}/alarms.csv ${SCRIPTDIR}/alarms.${hora}.csv
	fi
fi
