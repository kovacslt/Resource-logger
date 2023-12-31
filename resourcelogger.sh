#!/bin/bash
LOG="reslog.txt"
MAXENTRIES=0
# 0 -> a logfile mérete korlátlan

writelogentry ()
{
echo "Pillanatkép: " $(date +%Y%m%d-%T) >> $LOGFILE
echo "CPU szerint:" >>$LOGFILE
top -b -n 1 | head -n 16  >> $LOGFILE
echo "%MEM szerint:" >> $LOGFILE
top -b -n 1 -o %MEM| head -n 16 >> $LOGFILE
sensors | grep + >> $LOGFILE
iostat -x >> $LOGFILE
echo "========================================" >>$LOGFILE
}

getotherinstance ()

{
  FOUND=0
  declare LIST=($(pgrep -f "$MyBASE"))
  for A_PID in "${LIST[@]}"
  do
    if [ $A_PID != $MyPID ] && [ $A_PID != $BASHPID ]; then
    FOUND=$A_PID 
    fi 
  done
  echo $FOUND 
}

#itt indul
Myname=$(readlink -f $0)
MyPID=$$
MyBASE=$(basename $Myname)
IOST=$(which iostat)
 
if [ -z "$IOST" ]; then
       echo "Az iostat nincs telepítve, erre szükség van a működéshez. A program a sysstat csomag része, amit telepíthetsz például így: sudo apt install sysstat."
       
elif [ -n "$1" ]; then
 
 case $1 in

 install)
  eval DESKTOPFILE=~/.config/autostart/resourcelogger.desktop
  eval AUTOSTARTDIR=~/.config/autostart
  echo "Install: létrehozom az indítóbejegyzést: "$DESKTOPFILE
  mkdir -p $AUTOSTARTDIR
  cat <<_EOF > $DESKTOPFILE
[Desktop Entry]
Type=Application
Name=Resource logger
NoDisplay=false
Comment=
RunHook=0
X-GNOME-Autostart-enabled=true
Hidden=false
_EOF
  
echo "Exec=$Myname" >> $DESKTOPFILE
##Cinnamon hisztizhet, ha a.desktop nem végrehajtható jelölésű
chmod +x $DESKTOPFILE
echo "Az indítóbejegyzés rám mutat: "$Myname
echo "Elvileg kész az install"
;;

uninstall)
   eval DESKTOPFILE=~/.config/autostart/resourcelogger.desktop
   if [ -f $DESKTOPFILE ]; then
     echo "Törlöm az indítóbejegyzést: "$DESKTOPFILE
     rm $DESKTOPFILE
   else
     echo "Nem találtam a nevem alapján indítóbejegyzést: "$DESKTOPFILE
   fi  
;;

start)
  echo "Adatgyűjtés elindítása..."
  OTHERINST=$(getotherinstance)
 if [ $OTHERINST -eq 0 ]; then
 #ha nincs másik futó, indulhat egy
 echo "Háttérben indul: "$Myname
 $Myname & 
 else 
   echo "Van már futó példányom, nem indítok újat!"
fi 
;;

stop)
  echo "Adatgyűjtés leállítása..."
  OTHERINST=$(getotherinstance)
  while [ $OTHERINST -gt 0 ]; 
  do
  echo "Futó példány kilövése. PID="$OTHERINST  
   kill $OTHERINST
   OTHERINST=$(getotherinstance)
  done
;;
*) echo "Hibás paraméter: "$1
   echo "Érvényes paraméterek: start | stop | install | uninstall" 
;;

esac

else
     OTHERINST=$(getotherinstance)
     Starttime=$(date +%Y%m%d-%T) 
     eval LOGFILE='~/'$Starttime$LOG
     
     if [ $OTHERINST -gt 0 ]; then
       echo "Már van egy futó példányom!"     
     else
      echo "Logger elindult: "$Starttime > $LOGFILE
      echo "Adatgyűjtés elindult ide: "$LOGFILE
      #Mindenképp új logot csinál az indulás idejével a névben
      writelogentry
      #egy bejegyzést rögtön bele!
      CNT=$(wc -l < $LOGFILE )
     
      LOGLINECNT=$(($CNT))
      #kell a bejegyzés mérete, változhat rendszerenként: több CPU mag, több meghajtó 
      ENTRIES=1
      
      while true
      do
    
       writelogentry
       if [ $MAXENTRIES -gt 0 ] && [ $ENTRIES -gt $MAXENTRIES ]; then
         sed -i -e '2,'"$LOGLINECNT"'d' "$LOGFILE"
       else
        ((ENTRIES=ENTRIES+1))
       fi
       sleep 2
     
     done
   fi  
fi
