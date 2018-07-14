# LLD-Persistence

##Purpose
The purpose of this script is to create a persistent storage on a Live USB Stick. Without it, everything done on the Live OS will be deleted (or, to be more precise: never saved) from the USB and one starts with a fresh version. 
Although this can have advantages, it can be difficult for a normal workflow, as some personal files and settings may be necessary. This is where this Script comes in. It saves parts of the OS, 
which can then be recalled on the next start of the device. Because of the risky situation of having personal data on an easily loosable item like a Stick, the Data is securely encrypted.

##Usage
The script has three modes, which are given as parameter on Start:
0: A new persistent storage gets created. Only works when none is created already.
1: The persistent storage is applied. This means all chosen files from now on are saved to persistence (more on that later). Only works if there is one.
2: The persistent storage gets destroyed (shredded, no recovery possible!).

All of those require root rights. This is however normally no problem on a live OS. .desktop files will follow to call those options from the normal menu.
It works with an easy to follow GUI. In Option 0 the user will be asked for a password for the creation. After that, one can choose what shall be made persistent. 
The script is highly modular in that regard and can be extended without much bash knowledge, at the moment the following Options exist:
Home Directory: This will make the entire home folder of the user persistent. This includes basically all personal settings and directories and things like the desktop. This is recommended.
Persistent Folder: A more minimalist approach. A new Folder gets created in the Home directory that will from now on be persistent. Useless together with Home Directory.
Network: Saves Network Settings. If used together with the Home Directory Option, this means saving also encrypted WIFI access (which will immediately be used after applying persistent storage).
Printer: Printer Settings are saved and applied. 
**Note:** Porting Network and Printer to another Distribution can cause problems, as these rely on the network-manager and cups. If those aren't used in the other distribution, this has to be modified. 

After choosing, the persistent storage gets created and after a reboot, it can now be applied with option 1.
In Option 1, you will be asked for the password previously set. After that, its done!
Option 2 will ask you twice if your sure and, if you are, start the permanent deletion of the persistent storage. After that, it can be recreated with Option 0.

##Technique
The script is based in bash, with the use of cryptsetup, parted, rsync and zenity. Bash needs to be 4.2 or higher, with 
very basic Tools available (sed, tail, grep, cut, shred). Most of those tools are available in every Linux distribution out of the box. If not, they can be found in the repository with near to absolute certainty. 
For Example, Ubuntu needs the cryptsetup installed via
`sudo apt-get install cryptsetup`
The Encryption done with LUKS. In Option 0, on the remaining disk space of the USB, a partition is created and enrypted. In there, a folder is created for each of the different persistence options. 
The folders are filled with the content of the original Folder with rsync. In Option 1, the device is mounted and every folder is mounted over there chosen counterpart. 
Therefore, each interaction with those folders is now saved onto the encrypted drive. In Option 2, shred is used to clean the partition. Lastly, the partition itself is removed.

##Todo
The script is not entirely tested, its more like a beta, there may be very rough errors. It is not yet applicable for a normal use case! 
Missing are the aforementioned desktop files, so the script can be called from the menu. After that, the applying of the persistence should be asked after login (or maybe even before?). 
An install script should be written copying the script and the desktop files to their places and making them executable.
