#!/usr/bin/env python
# -*- coding: utf-8 -*-
import os, sys
from shutil import copyfile
from os.path import expanduser
try: input = raw_input
except NameError: pass
myhome = expanduser("~")
my_orig_bash_his_file = myhome + "/.bash_history"
my_bk_bash_his_file = myhome + "/.bash_history_bk"
if os.path.isfile(my_bk_bash_his_file):
    if input("Backup file .bash_history_bk exist, are you sure you want to replace .bash_history_bk ? (y/N) ").lower() != 'y':
        print("abort")
        exit()
copyfile(my_orig_bash_his_file, my_bk_bash_his_file)
if sys.version_info >= (3, 0):
    with open(my_bk_bash_his_file, "r", errors="ignore") as f:
        l = f.readlines()
else:
    with open(my_bk_bash_his_file, "r") as f:
        l = f.readlines()
#print(l)
s = []
new_i = False
for ll in l:
    if ll.startswith("#"):
        #print("\n" + ll)
        s.append("".join(["\n", ll]))
        new_i = True
    else:
        if new_i:
            s.append(ll.strip())
            new_i = False
        else:
            s.append("".join([ll.strip(), "\\n"]))
s.append("\n")
#print(s)
with open(my_orig_bash_his_file, "w") as f:
    f.writelines(s)
print "Done format. To take effect, please open new tab to start new bash session and run your hisblock.sh"

