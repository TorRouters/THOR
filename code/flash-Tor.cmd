@echo off
cd data
bash flash.sh

echo "launching web managment"
SET chrome="C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
%chrome% -incognito "http://192.168.7.1:8080/"
%chrome% -incognito "https://check.torproject.org/"

echo
echo "Thank you for using our script, please consider supporting us to keep this project alive"
echo "would you like to open donation page?"


SET AREYOUSURE=Y
SET /P AREYOUSURE=Is it OK to open donation page? ([Y]/N)?
IF /I "%AREYOUSURE%" NEQ "Y" GOTO END

%chrome% "https://www.buymeacoffee.com/huskyLOVE"


:END
echo [+] - don't forget to set Wi-Fi password and Control Panel root password.
echo [+] - all done
pause
