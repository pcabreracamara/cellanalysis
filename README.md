# cellanalysis
CellAnalysis is the main project from fakebts.com to detect fake 2G stations

Installation with OsmocomBB phones:

  Once you have downloaded “cell_analysis_version.tar.gz”, create a directory where you want to run and follow these steps to get started.

  1) Locate osmocom-bb binaries, we are going to need two of them: “cell_log” th and “ccch_scan“. Usually found on the following paths from osmocom-bb main directory
  <path_to_osmocom-bb>/src/host/layer23/src/misc/
  
  2) Edit the file “cell_analysis.sh“, you'll see in the first two lines the parameters which you must verify in order to check the two binaries paths that we have obtained in the previous step.
  # OSMOCOM binaries paths
  CELLBIN=”/opt/osmocom-bb/src/host/layer23/src/misc/cell_log”
  CCCHBIN=”/opt/osmocom-bb/src/host/layer23/src/misc/ccch_scan”
  
  3) If you want to receive alerts via email, make sure you have postfix server already configured (tutorial to install and configure on  Ubuntu) and edit the file “check_cells.sh“. You must replace “root” account by an external mail account where you want to receive   alarms and notifications.

  4) Finally, add to the user's cron file this lines to run the two scripts every 10 minutes:
  0,10,20,30,40,50 * * * * <path_files>/cell_analysis.sh > /dev/null 2>&1
  0,10,20,30,40,50 * * * * <path_files>/check_cells.sh > /dev/null 2>&1
  Note: check after this step that the two script files have execution permissions. If you are not sure, run this command in the directory where you have unzipped the files:

  chmod x cell_analysis.sh check_cells.sh

Using the program

  To start using Cell Analysis, “Layer 1” application should be running on the osmocomBB phone. To do this we must connect, with the phone off, the USB cord to the computer and the other end to the phone serial port. We will find the osmocon binary “path” and then, upload the firmware.
  
  Until this moment we haven't seen any output from the command line, but once we press the power button of the phone slightly. we will start seeing how it uploads the firmware:

Received PROMPT2 from phone, starting download
....
handle_write(): finished

Once the software is loaded correctly, we will see in the terminal the application “Layer 1“.

If you have followed the installation steps, from now on Cell Analysis will be running.

This is the best time to check that everything is properly installed and configured, by manually running “cell_analysis.sh“:

root@kali:/opt/osmocom-bb# ./cell_analysis.sh
Leyendo celdas cercanas …
Procesando canal: 15
Se escriben los datos de trafico al fichero: 15.csv
Procesando canal: 121
Se escriben los datos de trafico al fichero: 121.csv
Terminado
root@kali:/opt/osmocom-bb#


Output Files

The program will generate the following files, that we will see in more detail below:

XXXX.csv (where XXXX is the cell ARFCN)
ignore.csv
alarms.csv
error.log
XXXX.csv

The file name is the channel or ARFCN from the cell found by the Osmocom phone, and the columns that make up the file, ordered as they appear, are as follows:

Time Stamp formed by: “day month hour:minute“
CGI (Cell Global Identification): cell identifier, made of: MCC_MNC_LAC_CI (for more information see document GSM 03.03 “Numbering, addressing and identification”)
Cell ARFCN
MCC
MNC
Operator Name
Number of subscribers found during the monitoring
Number of channels used by the cell
As an example, a fragment of the cell ARFCN “111“, LAC “4963” and CellID “BB22” is the following:

02/09 01:26;214_1_4963_BB22;111;214;01;(Spain, Vodafone);23;2
02/09 01:31;214_1_4963_BB22;111;214;01;(Spain, Vodafone);51;2
02/09 01:41;214_1_4963_BB22;111;214;01;(Spain, Vodafone);25;2

ignore.csv

This file contains measures that are discarded due to poor quality. The meaning and column order are the same for cell files “XXXX.csv”, but also containing three additional columns:

Number of burst errors “IND BURST”
Number of errors discard “Dropping Frames”
Number of errors FBSB
Examples:

24/02 23:22;214_7_0AA0_0BB0;18;214;07;(Spain, movistar);109;1;412;0;0
24/02 23:22;214_7_0AA0_0BB0;18;214;07;(Spain, movistar);159;1;256;2;0
In the first line we can see the amount of “IND BURST” errors, these are 412 from the 533 total lines (+/- 77%), therefore this file is discarded.

alarms.csv

This file contains the cell information whenever Cell Analysis finds it and classifies as fake. The format and content of the columns are identical to that shown for cell files “XXXX.csv“.

For example, take a look at this alarm:

19/02 08:48;214_22_03E8_000A;1;214;22;(Spain, DigiMobil);0;1
We see that over the time the monitoring has lasted, no subscriber has been found in the cell. In the alarm we can easily identify the fake cell data: MCC=214, MNC=22, LAC =”03E8″ and CI=”000A”.

error.log

Unfortunately, sometimes errors occur in the “Layer 1” making the osmocom terminal unsuitable, so it will not detect any cell. When these errors start appearing, they will be recorded and when the number of errors exceeds the threshold, the program will send a warning mail to admisnistrador and stop automatically, as it is required to restart the phone and upload the firmware again (see “Using the program“)
