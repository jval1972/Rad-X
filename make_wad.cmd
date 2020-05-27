make_radixdef -o SCRIPT\radixdef.inc -i WADSRC\DOOM\DOOMALIAS.txt -i WADSRC\RADIX\BASEACTORS.txt -i WADSRC\RADIX\RADIXPICKUPS.txt -i WADSRC\RADIX\RADIXENEMIES.txt -i WADSRC\RADIX\RADIXWEAPONS.txt -i WADSRC\RADIX\FORCEFIELD.txt -i WADSRC\RADIX\RADIXSPLASHES.txt -i WADSRC\RADIX\ACTORALIAS.txt
cd .\WADSRC
"C:\Program Files\7-Zip\7z.exe" a -r ..\..\bin\RAD.zip *.*
move ..\..\bin\RAD.zip ..\..\bin\RAD.pk3
dir ..\..\bin\RAD.pk3
pause