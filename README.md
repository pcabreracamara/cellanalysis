# cellanalysis
CellAnalysis is the main project from fakebts.com to detect fake 2G stations

There are 3 main scripts to start using CellAnalysis:

`cell_analysis.sh`        (To be used with OsmocomBB phones)<br>
`cell_analysis_rtl.sh`    (To be used with RTL-SDR devices)<br>
`cell_analysis_uhd.sh`    (To be used with USRP UHD devices)<br>

Index:
1) Installation
2) Using CellAnalysis
3) Output files

********************************************************************************
1) Installation
********************************************************************************

Following are described how to setup everything, depending the hardware you want to use:

1.1) Installation with OsmocomBB phones: 

  Once you have downloaded “cell_analysis_version.tar.gz”, create a directory where you want to run and follow these steps to get started.

  1.1.1) Locate osmocom-bb binaries, we are going to need two of them: “cell_log” th and “ccch_scan“. Usually found on the following paths from osmocom-bb main directory
  `<path_to_osmocom-bb>/src/host/layer23/src/misc/`
  
  1.1.2) Edit the file “cell_analysis.sh“, you'll see in the first two lines the parameters which you must verify in order to check the two binaries paths that we have obtained in the previous step.
  `# OSMOCOM binaries paths`<br>
  `CELLBIN=”/opt/osmocom-bb/src/host/layer23/src/misc/cell_log”`<br>
  `CCCHBIN=”/opt/osmocom-bb/src/host/layer23/src/misc/ccch_scan”`
  
  1.1.3) If you want to receive alerts via email, make sure you have postfix server already configured (tutorial to install and configure on  Ubuntu) and edit the file `check_cells.sh`. You must replace “root” account by an external mail account where you want to receive   alarms and notifications.

  1.1.4) Finally, add to the user's cron file this lines to run the two scripts every 10 minutes:
  `0,10,20,30,40,50 * * * * <path_files>/cell_analysis.sh > /dev/null 2>&1`<br>
  `0,10,20,30,40,50 * * * * <path_files>/check_cells.sh > /dev/null 2>&1`
  Note: check after this step that the two script files have execution permissions. If you are not sure, run this command in the directory where you have unzipped the files:
  `chmod x cell_analysis.sh check_cells.sh`
  
1.2) Installation with RTL-SDR devices:

  1.2.1) Locate kalibrate and airprobe-rtl binaries, We will need two of them: “gsm_receive_rtl.py” th and “kal“. Usually found on the following paths:
  `<path_to_airprobe>/gsm_receiver/src/python/`<br>
  `/usr/local/bin/kal`
  
  1.2.2) Edit the file “cell_analysis_rtl.sh“, you'll see in the first two lines the parameters which you must verify in order to check the two binaries paths that we have obtained in the previous step.
  `HEART of the =”/usr/local/bin/kal”`<br>
  `GSMRECPATH=”/opt/airprobe/gsm-receiver/src/python/”`
  
  In the following lines we can configure the spectrum bands where we want our rtl-sdr device to scan for cells. Usually these devices' tuners only show consistent values ​​in the 900MHz band, so by default this will be the band set:
  `# GSM900: Banda de los 900Mhz`<br>
  `# DSC: Banda de los 1800Mhz`<br>
  `#BANDS =”GSM900 DCS”`<br>
  `Bandas = GSM900`
  If you want to add more bands, add them separated by a space. The list of bands supported by kalibrate-rtl is: GSM850, GSM-R, GSM900, EGSM, DCS y PCS.

  1.2.3) If you want to receive alerts via email, make sure you have postfix server already configured and edit the file “check_cells.sh“. You must replace “root” account by an external mail account where you want to receive alarms and notifications.

  1.2.4) Finally, add to the user's cron file this lines to run the two scripts every 10 minutes
  `0,10,20,30,40,50 * * * * <path_files>/cell_analysis_rtl.sh > /dev/null 2>&1`<br>
  `0,10,20,30,40,50 * * * * <path_files>/check_cells.sh > /dev/null 2>&1`

  Note: check after this step that the two files have execution permissions:
  `chmod x cell_analysis_rtl.sh check_cells.sh`
  
1.3) Installation with USRP UHD devices:

  1.3.1) Locate kalibrate and airprobe-uhd binaries , We will need two of them: “gsm_receive_usrp.py” th and “kal“. Usually found on the following paths:
  `<path_to_airprobe>/gsm_receiver/src/python/`<br>
  `/usr/local/bin/kal`
  Aside these binaries, we will also use tshark (Wireshark command line).

  1.3.2) Edit the file “cell_analysis_uhd.sh“, you'll see in the first two lines the parameters which you must verify in order to check the two binaries paths that we have obtained in the previous step.
  `TSHARKBIN=”/usr/bin/tshark”`<br>
  `HEART of the =”/usr/local/bin/kal”`<br>
  `GSMRECPATH=”/opt/airprobe/gsm-receiver/src/python/”`
  
  The following lines configure the bands in which our cells UHD device searches. NOTE: the binary-uhd kalibrate must be patched to work properly in the EGSM band, otherwise the execution will not show any cell found. Set the default values ​​of the bands to your discretion, considering that those bands are not included no cells are detected false.
  `# GSM900: Banda de los 900Mhz (P equivalent to the Primary GSM-GSM)`<br>
  `# EGSM: Banda de los 900Mhz (equivalent to E-GSM Extended GSM)`<br>
  `# DSC: Banda de los 1800Mhz`<br>
  `#BANDS =”GSM900 DCS”`<br>
  `Bandas = GSM900`

  1.3.3) If you want to receive alerts via email, make sure you have postfix server already configured (tutorial to install and configure on Ubuntu) and edit the file “check_cells.sh“. You must replace “root” account by an external mail account where you want to receive alarms and notifications.

  1.3.4) Finally, add to the user's cron file this lines to run the two scripts every 10 minutes
  `0,10,20,30,40,50 * * * * <path_files>/cell_analysis_uhd.sh > /dev/null 2>&1`<br>
  `0,10,20,30,40,50 * * * * <path_files>/check_cells.sh > /dev/null 2>&1`

  Note: check after this step that the two script files have execution permissions:
  `chmod x cell_analysis_uhd.sh check_cells.sh`
  
********************************************************************************
2) Using the program
********************************************************************************

2.1) OsmocomBB phones

  To start using Cell Analysis, “Layer 1” application should be running on the osmocomBB phone. To do this we must connect, with the phone off, the USB cord to the computer and the other end to the phone serial port. We will find the osmocon binary “path” and then, upload the firmware.
  
  Until this moment we haven't seen any output from the command line, but once we press the power button of the phone slightly. we will start seeing how it uploads the firmware:

  `Received PROMPT2 from phone, starting download`<br>
  `....`<br>
  `handle_write(): finished`

Once the software is loaded correctly, we will see in the terminal the application “Layer 1“. If you have followed the installation steps, from now on Cell Analysis will be running. This is the best time to check that everything is properly installed and configured, by manually running `cell_analysis.sh`.

2.2) RTL-SDR devices:

  RTL-SDR devices requires no specific firmware or complicated steps, you must connect your device to any free USB port in your computer and manually running `cell_analysis_rtl.sh`.
  
2.3) USRP UHD devices:

 UHD hardware is precision, stability and that it doesn't require complicated steps or specific firmware, so manually run `cell_analysis_uhd.sh`.

********************************************************************************
3) Output Files
********************************************************************************

The program will generate the following files, that we will see in more detail below:

  3.1) XXXX.csv (where XXXX is the cell ARFCN)
  3.2) ignore.csv
  3.3) alarms.csv
  3.4) error.log
  3.5) XXXX.csv

  3.1) The file name is the channel or ARFCN from the cell found by the Osmocom phone, and the columns that make up the file, ordered as they appear, are as follows:

  Time Stamp formed by: “day month hour:minute“
  CGI (Cell Global Identification): cell identifier, made of: MCC_MNC_LAC_CI (for more information see document GSM 03.03 “Numbering, addressing and identification”)
  Cell ARFCN
  MCC
  MNC
  Operator Name
  Number of subscribers found during the monitoring
  Number of channels used by the cell
  
  As an example, a fragment of the cell ARFCN “111“, LAC “4963” and CellID “BB22” is the following:
  `02/09 01:26;214_1_4963_BB22;111;214;01;(Spain, Vodafone);23;2`<br>
  `02/09 01:31;214_1_4963_BB22;111;214;01;(Spain, Vodafone);51;2`<br>
  `02/09 01:41;214_1_4963_BB22;111;214;01;(Spain, Vodafone);25;2`

3.2) ignore.csv

  This file contains measures that are discarded due to poor quality. The meaning and column order are the same for cell files “XXXX.csv”, but if you are running an OsmocomBB phone also will containing three additional columns:

  Number of burst errors “IND BURST”
  Number of errors discard “Dropping Frames”
  Number of errors FBSB
  
  Examples:
  `24/02 23:22;214_7_0AA0_0BB0;18;214;07;(Spain, movistar);109;1;412;0;0`<br>
  `24/02 23:22;214_7_0AA0_0BB0;18;214;07;(Spain, movistar);159;1;256;2;0`
  
  In the first line we can see the amount of “IND BURST” errors, these are 412 from the 533 total lines (+/- 77%), therefore this file is discarded.
  
  For RTL-SDR and USRP devices, when the signal level is not adequate and depending on the hardware you're using, we can read very few messages (or none).
  
  Examples:
  `23/09 00:47;-;11;;;;0;;;;`<br>
  `23/09 00:52;-;16;;;;0;;;;`

alarms.csv
  This file contains the cell information whenever Cell Analysis finds it and classifies as fake. The format and content of the columns are identical to that shown for cell files “XXXX.csv“.

  For example, take a look at this alarm:
  `19/02 08:48;214_22_03E8_000A;1;214;22;(Spain, DigiMobil);0;1`
  
  We see that over the time the monitoring has lasted, no subscriber has been found in the cell. In the alarm we can easily identify the fake cell data: MCC=214, MNC=22, LAC =”03E8″ and CI=”000A”.

error.log
  Errors will be reported to this file:
    - Sometimes errors occur in the “Layer 1” making the osmocom terminal unsuitable, so it will not detect any cell. When these errors start appearing, they will be recorded and when the number of errors exceeds the threshold, the program will send a warning mail to admisnistrador and stop automatically, as it is required to restart the phone and upload the firmware again.
    - If a hardware error occurs by which we can not access the RTL-SDR or USRP UHD device or the devices does not find any cell, Cell Analysis will notify the situation by generating this file.
    
