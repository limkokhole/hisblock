# hisblock
highlight bash history by time block

How to use:  

[0] Ensure you has installed commands like tput, rg (ripgrep) ...etc which used in hisblock.sh.  
 
[1] Ensure your ~/.bash_aliases has this content (don't forget delete ~/.bashrc's `HISTSIZE=1000` 和 `HISTFILESIZE=2000` ), `hisunique` is a function list all the unique comment count(optional). Old gdb need explicitly set some values for both `HISTSIZE` and `HISTFILESIZE` instead of leave it empty. Then do `source ~/.bash_aliases`:  

HISTTIMEFORMAT="%Y/%m/%d %T " 
alias histime='history'  
alias hisdefault='(HISTTIMEFORMAT=""; history;)'  
alias h=hisdefault  
HISTFILESIZE=   
HISTSIZE=   
HISTCONTROL=ignoreboth  
function hisunique()  
{  
    hisdefault | awk '{CMD[$2]++;count++;}END { for (a in CMD)print CMD[a] " " CMD[a]/count*100 "% " a;}' | grep -v "./" | cat -v | column -c3 -s " " -t | sort -nr | nl |  head -n100000  
}  


[2] Type some commands to test, so your bash_history will saved the commands with latest timestamp format once you close current tab.

[3] After done #[2] a while, run python file his_format.py to format ~/.bash_histoy (i.e. merge multiple lines into single for further parsing):  

$ `python his_format.py`  

[4] `chmod +x hisblock.sh`  

[5] Open new bash session in new tab. Run the script with desired date range, 120 here means if the next command is 120 seconds older than previous command, then it will list as new color time block. This will help if you have a lot of similar commands and you have no idea which commands is reside the same time range which you repeatly used in certain amount of time.   

E.g. you repeatly do `cp <path A> <path B>` and `cp <path A> <path C>`, and then take a coffee for 5 minutes. Now you come back to seat and perform the next task: `cp <path X> <path Y>`, but this `<path X/Y>` saved in history should distinguish from previous  `<path A/B/C>`. The color output grouped by time block make it obvious. 

Then I can copy/reuse the `cp <path A> <path B>` and `cp <path A> <path C>` without have to worry or calculate the time manually to know `cp <path X> <path Y>` is relevant or not. **The color by time block make it clear in first glance.**. You can increase or decrease the 120 seconds to suit your needs.

`. hisblock.sh '2017/09/04 18:10:00 2017/09/04 18:10:55' 120`  


[6] `. hisblock.sh` print help:  
        BASIC SYNOPSIS:  
                source hisblock.sh SINGLE_QUOTE [from_date] [from_time] [to_date] [to_time] SINGLE_QUOTE interval_in_seconds [B|D]  
        Example Usage:  
                . hisblock.sh '2015/05/21' 120 #entire day  
                . hisblock.sh '01:30:00 07:30:00' 120 #default today  
                . hisblock.sh '2015/05/21 01:30:00 07:30:00' 120 #same day  
                . hisblock.sh '2015/05/21 01:30:00 2015/05/22 12:30:00' 120 B #'B' stands for fixed time Block  
                . hisblock.sh '2015/05/21 01:30:00 2015/05/22 12:30:00' 120 #120 seconds  
                . hisblock.sh '2015/05/21 01:30:00 2015/05/22 12:30:00' 15 D #'D' for distance between each history line instead of fixed block, default  
        Tips:  
            Use his.py to format your history which probably consist of multiple lines  
            
![Alt text](/1510178071_2017-11-09_Z6x5SE5t9N.png?raw=true "Optional Title")

WARNING:  
Always backup the `~/.bash_history`, even a simple experiment `>~/.bash_aliases` will truncate your `~/.bash_history` to default value and you will cry. The `his_format.py` will save your backup as `~/.bash_history_bk`, you can revert back if something went wrong.  

I advise you backup history file on boot by using `crontab -e`. Perform this checking before replace the history file to avoid backup the truncated history file if something went wrong. (you should routinely adjust 365143 part to your current total lines until your history > default 2000, and also `<username>` and pls_check_bash_history path):  
    
```bash
SHELL=/bin/bash
@reboot if [[ $(wc -l </home/<username>/.bash_history) -ge 365143 ]]; then cp /home/<username>/.bash_history /home/<username>/.bash_history_reboot_bk; else echo $(wc -l </home/<username>/.bash_history) > /home/<username>/Downloads/pls_check_bash_history; fi
```
Or even better, backup to local and upload it to cloud by systemd. (I noticed sysVInit will no network if shutdown from gnome menu, and "# Required-Start:   $network" will never conform, so we better off to use systemd):

```bash
[1] Install gdrive
$ sudo apt install golang-go
$ mkdir ~/.go
$ echo "GOPATH=$HOME/.go" >> ~/.bashrc
$ echo "export GOPATH" >> ~/.bashrc
$ echo "PATH=\$PATH:\$GOPATH/bin # Add GOPATH/bin to PATH for scripting" >> ~/.bashrc
$ . ~/.bashrc
$ go get golang.org/x/oauth2/google
$ go get github.com/prasmussen/gdrive
$ cd ~/.go/src/github.com/prasmussen/gdrive/
$ go install #executable gdrive created in $GOPATH/bin

[2: UPDATE] You should create your own app and modify handlers_drive.go file, See my answer at https://stackoverflow.com/a/59353414/1074998

[2] Run gdrive
$ gdrive list #setup oauth first
Authentication needed
Go to the following url in your browser:
https://accounts.google.com/o/oauth2/auth?... #copy and open the link in web browser to get verification code

Enter verification code: 1/5XXXXXX_VERIFICATION_CODE
...

$ gdrive mkdir bk_bash_history
Directory 2YYYYYYYYYYY_FOLDER_ID created

$ gdrive upload /home/<username>/.bash_history -p 2YYYYYYYYYYY_FOLDER_ID
Uploading /home/<username>/.bash_history
Uploaded 5JJJJJJJJ_FILE_ID at 3.9 MB/s, total 9.5 MB

$ gdrive update 5JJJJJJJJ_FILE_ID /home/<username>/.bash_history
Uploading /home/<username>/.bash_history
Updated 5JJJJJJJJ_FILE_ID at 3.2 MB/s, total 9.5 MB

$ gdrive revision list 5JJJJJJJJ_FILE_ID #revision will be deletet if 30 days or >100 revisions
Id                                                    Name            Size     Modified              KeepForever
0A-AAAAAA_ZZZZZZZZZZZZZZZ_REVISION_ID   .bash_history   9.5 MB   2017-11-16 20:08:42   False
0A-AAAAAA_ZZZZZZZZZZZZZZZ_REVISION_ID   .bash_history   9.5 MB   2017-11-16 20:09:24   False

[3] Setup systemd service file to backup to local and gdrive on reboot/shutdown #routinely adjust the 365143 total lines until your history total > default 2000 #Also adjust the 5JJJJJJJJ_FILE_ID, and relevant <username> path of course.
$ cat /home/<username>/n/sh/bk_file.sh #create the script which will be run by systemd service
#!/bin/bash
GOPATH=/home/<username>/.go
PATH=$PATH:$GOPATH/bin
if [[ $(wc -l </home/<username>/.bash_history) -ge 365143 ]]; then cp /home/<username>/.bash_history /home/<username>/.bash_history_reboot_bk; if ! gdrive update 5JJJJJJJJ_FILE_ID /home/<username>/.bash_history >/tmp/gdrive_update.log 2>&1; then cp /tmp/gdrive_update.log /home/<username>/Downloads/gdrive_update_failed.log; fi; else echo $(wc -l </home/<username>/.bash_history) > /home/<username>/Downloads/pls_check_bash_history; fi

$ chmod +x /home/<username>/n/sh/bk_file.sh #make that script executable

$ cat /etc/systemd/system/bk_file.service #create the systemd service file, adjust the "ExecStop =" path and "User ="
[Unit]
Description = bk files like ~/.bash_history to gdrive before shutdown/reboot
After = network.target network-online.target nss-lookup.target

[Service]
Type = oneshot
RemainAfterExit = true
ExecStart = /bin/true
ExecStop = /home/<username>/n/sh/bk_file.sh
User = <username>

[Install]
WantedBy = multi-user.target

$ sudo systemctl enable bk_file --now #enable the systemd service
$ sudo systemctl daemon-reload #just in case
```










