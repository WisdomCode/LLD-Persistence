#!/bin/bash

username=$(getent passwd 1000 | cut -d: -f1)

PersistenceOptions=(\
"True" 
"HOME Directory" 
"Choosing this will make all personal folders
and most personal settings persistent.
Not to be combined with the consistence folder" 
"/home/$username/" 
"home/" 

"False" 
"Persistent Folder" 
"Choosing this will create a folder 
in you personal files that will be persistent 
throughout boots. Not the be combined with the 
HOME Directory, as this one will make all 
home folders in the persistent already." 
"/home/$username/persistent/" 
"homefolder/" 

"True" 
"Network" 
"Make the Network Settings persistent. 
Combined with HOME Folder, this will 
include WIFI Connections with passwords." 
"/etc/NetworkManager/system-connections/" 
"network/" 

"False" 
"Printer" 
"Include your printer 
setup into persistence" 
"/etc/cups/" 
"printer/"
)


#create a dictionary:
declare -A persource
declare -A perdest
listargs=""
m=""
n=0
for i in "${PersistenceOptions[@]}"
do
if [ "$n" = "1" ]; then m="$i"; fi
echo "$n"
case $n in
	[0-2])
		listargs+=("$i")
		;;
	"3")
		persource["$m"]="$i"
		;;
	"4")
		perdest["$m"]="$i"
		;;
esac
n=$(expr $n + 1)
if [ "$n" = "5" ]; then n=0; fi;
done


usbdev=$(df | grep /cdrom | cut -d " " -f1)
partition=$(ls $usbdev? | tail -n 1 | sed 's=/dev/==g')

createpassword() {
while :
do
	i=$(zenity --entry --hide-text --text "Please choose a password for the encryption of your Data.\nBE WARNED: THERE IS NO WAY TO RECOVER YOUR DATA IF THE PASSWORD IS LOST" --title "Persistent Storage Creation")
	if ! [ "$?" = "0" ]; then exit; fi
	j=$(zenity --entry --hide-text --text "Retype it" --title "Persistent Storage Creation")
	if ! [ "$?" = "0" ]; then exit; fi
	if [ "$i" = "$j" ]
	then
		echo "$i"
		break
	else
		zenity --warning --text "The Input does not match!"
	fi
done
}
choosing() { zenity --list --title="Choose Persistence" --text "Choose what will be persistent" --multiple --checklist --column "Choose" --column "Name" --column "Description" "${listargs[@]}" --width=600 --height=800; if ! [ "$?" = "0" ]; then exit; fi; }
areyousure() {
zenity --question --title="Linuxaria introduction to Zenity" --text "Do you want to delete you persistent Data?"
if ! [ "$?" = "0" ]; then exit; fi
zenity --question --title="Linuxaria introduction to Zenity" --text "This will permanently erase you Data. Do you want to stop this Operation now?"
if ! [ "$?" = "1" ]; then exit; fi
}
askforpass() { zenity --entry --hide-text --text "Type your Password for your persistent Data" --title "Persistent Storage restore"; if ! [ "$?" = "0" ]; then exit; fi; }
waiting() { zenity --progress --no-cancel --auto-close --title "$1" --text="$2"; }
youdidit() { zenity --info --title "Finished" --text "Congratulations, you now have a persistent Storage setup. It can be used after a reboot.\nPlease acknowledge that your Data collected now will not be saved into persistence." ; if ! [ "$?" = "0" ]; then exit; fi; }


createper() {
if ! lsblk --fs  | grep -q "$partition.*crypto_LUKS"
	then
	#create partition:
	offset=$(($(cat /sys/block/$usbdev/$partition/start)+$(cat /sys/block/$usbdev/$partition/size)))
	parted -s $usbdev unit s mkpart primary $offset 100%
	partition=$(ls $usbdev? | tail -n 1 | sed 's=/dev/==g')

	#Create Password
	PASS=$(createpassword)
	(
	printf "$PASS\n" | cryptsetup luksFormat /dev/$partition
	printf "$PASS\n" | cryptsetup luksOpen /dev/$partition persistent
	mkfs.ext4 -L persistent /dev/mapper/persistent
	) | waiting "Preparing Persistence" "Creating encrypted space for persistent Data. This should take less than a minute"
	zenitychoice=$(choosing)
	(
	mkdir /media/persistent
	mount /dev/mapper/persistent /media/persistent
	IFS='|' read -r -a choices <<< "$zentitychoice"
	for element in "${choices[@]}"
	do
		if [ "$element" = "Persistent Folder"]
			then mkdir "${persource[$element]}"
		fi
		mkdir -p /media/persistent/${perdest[$element]}
		rsync -a "${persource[$element]}" "/media/persistent/${perdest[$element]}"
	done
	echo "$zentitychoice" > /media/persistence/perconf
	umount /media/persistent
	cryptsetup luksClose persistent
	) | waiting "Copying Data" "The Data of your current Session is now copied to the persistent Storage.\nThis takes Time depending on how much Data you have aquired and how fast your Stick is."
	youdidit
fi
}


mountper() {
if lsblk --fs  | grep -q "$partition.*crypto_LUKS" && [ ! -d "/media/persistent" ]
then
	PASS=askforpass
	printf "$PASS\n" | cryptsetup luksOpen /dev/$partition persistent
	mkdir /media/persistent
	mount /dev/mapper/persistent /media/persistent
	config=$(</media/persistence/perconf)
	IFS='|' read -r -a choices <<< "$config"
	for element in "${choices[@]}"
	do
		if [ "$element" = "Persistent Folder"]
			then mkdir "${persource[$element]}"
		fi
		mount --bind "/media/persistent/${perdest[$element]}" "${persource[$element]}"
		if [ "$element" = "Network" ]
			then systemctl restart network-manager.service
		fi
		if [ "$element" = "Printer" ]
			then systemctl restart cups.service
		fi
	done
fi
}

deleteper() {
if lsblk --fs  | grep -q "$partition.*crypto_LUKS"
then
	areyousure
	if [ -d "/media/persistent" ]
		then umount /media/persistent
	fi
	(
	shred -vzn 0 /dev/$partition
	parted -s $usbdev rm "${partition: -1}"
	) | waiting "Erasing" "The Persistent storage gets now erased securely. This can take a while, depending on how much there is.\nWhen this window is closing, its finished.\nDo not turn off your PC until then."
fi

case "$1" in
        "0")
            createper()
            ;;

        "1")
            mountper()
            ;;

        "2")
            deleteper()
            ;;

        *)
            echo "Invalid Input, try '0', '1' or '2'"
            exit 1
esac
