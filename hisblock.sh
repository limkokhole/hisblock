#!/usr/bin/env bash
#Author: <limkokhole@gmail.com>
fname="hisblock.sh"
h_tmp_f="/tmp/hisblock.log"
h_tmp_f2="/tmp/hissorted.log"
p_usage () {
    echo -e "
        BASIC SYNOPSIS:
                source ${fname} SINGLE_QUOTE [from_date] [from_time] [to_date] [to_time] SINGLE_QUOTE interval_in_seconds [B|D]
        Example Usage:
                . ${fname} '2015/05/21' 120 #entire day
                . ${fname} '01:30:00 07:30:00' 120 #default today
                . ${fname} '2015/05/21 01:30:00 07:30:00' 120 #same day
                . ${fname} '2015/05/21 01:30:00 2015/05/22 12:30:00' 120 B #'B' stands for fixed time Block
                . ${fname} '2015/05/21 01:30:00 2015/05/22 12:30:00' 120 #120 seconds
                . ${fname} '2015/05/21 01:30:00 2015/05/22 12:30:00' 15 D #'D' for distance between each history line instead of fixed block, default
        Tips:
            Use his.py to format your history which probably consist of multiple lines
"
}

h_swap () {
    if (( "$start_t" > "$end_t" )); then #swap to ignore "to timestamp" and "from timestamp" arg order
        read start_t end_t <<<"$end_t $start_t"
    fi
}

#u must use source OR dot(like how .bashrc do) to run this script bcoz history corrupted even u do `HISTFILE=~/.bash_history` and `set -o history`
if [[ "$(basename -- "$0")" == "$fname" ]]; then
    echo "Don't run $0, instead please use source OR better use . dot" >&2
    p_usage
    exit #can only `return' from a function or sourced script
fi

do_distance=true
if [ "$#" -eq 3 ]; then
    if [[ "$3" == 'B' ]]; then
        do_distance=false
    fi
    t_block="$2"
elif [ "$#" -eq 2 ]; then
	t_block="$2"
else
    p_usage
    return #sourcing don't use exit
fi

d_atom=(`echo ${1}`)
d_len="${#d_atom[@]}"
if (( "$d_len" == 4 )); then
    start_t="$(date -d "${d_atom[0]} ${d_atom[1]}" +%s)" #start timestamp
    end_t="$(date -d "${d_atom[2]} ${d_atom[3]}" +%s)" #end timestamp
elif (( "$d_len" == 3 )); then
    start_t="$(date -d "${d_atom[0]} ${d_atom[1]}" +%s)" #start timestamp
    end_t="$(date -d "${d_atom[0]} ${d_atom[2]}" +%s)" #end timestamp
elif (( "$d_len" == 2 )); then
    today_d="$(date '+%Y/%m/%d')"
    start_t="$(date -d "${today_d} ${d_atom[0]}" +%s)" #start timestamp
    end_t="$(date -d "${today_d} ${d_atom[1]}" +%s)" #end timestamp
elif (( "$d_len" == 1 )); then
    start_t="$(date -d "${d_atom[0]} 00:00:00" +%s)" #start timestamp
    end_t="$(date -d "${d_atom[0]} 23:59:59" +%s)" #end timestamp
else
    p_usage
    return
fi
if [[ "$start_t" =~ ^[0-9]+$ && "$end_t" =~ ^[0-9]+$ && "$t_block" =~ ^[0-9]+$ ]]; then :; else p_usage; return; fi;
h_swap

HISTTIMEFORMAT="%s %Y/%m/%d %T "
next_t="0"

p_red=$(tput setaf 1)
p_green=$(tput setaf 10)
p_yellow=$(tput setaf 11)
p_blue=$(tput setaf 21)
p_orig=$(tput sgr0)
c_arr=($p_red $p_green $p_yellow)
c_arr_len="${#c_arr[@]}"
color_index=0

history >"$h_tmp_f"
printf "%s\n" "START $start_t `date -d @${start_t}`" >>"$h_tmp_f"
printf "%s\n" "END $end_t `date -d @${end_t}`" >>"$h_tmp_f"
sort -k2 -n "$h_tmp_f" > "$h_tmp_f2"
start_index="$(rg -n "^S" "$h_tmp_f2"|cut -f1 -d: )"
end_index="$(rg -n "^E" "$h_tmp_f2" |cut -f1 -d: )"
re='^[0-9]+$'
if ! [[ $start_index =~ $re ]] ; then #Not a single number will failed here
    echo "Failed due to command is multi-lines in history. Please run 'python his_format.py' to format it first. Abort" >&2
    return
fi
if ! [[ $end_index =~ $re ]] ; then
    echo "Failed due to command is multi-lines in history. Please run 'python his_format.py' to format it first. Abort" >&2
    return
fi
set -f #noglob
if [ "$do_distance" = false ] ; then #block
    sed -n $(($end_index + 1))'q;'"$start_index","$end_index"p "$h_tmp_f2" |  while read -r line; do
        h_atom=(`echo "${line}"`)
        curr_t="${h_atom[1]}"
        if (( "$curr_t" > "$next_t" )); then
            printf "%s" "${c_arr[ $(($color_index % $c_arr_len)) ]}"
            ((color_index+=1))
            ((next_t="$curr_t"+"$t_block"))
        fi
        h_tail=( "${h_atom[@]:2}" )
        echo "${h_atom[0]} ${h_tail[@]}"
    done
else #distance
    prev_t=0
    sed -n $(($end_index + 1))'q;'"$start_index","$end_index"p "$h_tmp_f2" |  while read -r line; do
        h_atom=(`echo "${line}"`)
        curr_t="${h_atom[1]}"
        if (( $(($curr_t - $prev_t)) > "$t_block" )); then
            printf "%s" "${c_arr[ $(($color_index % $c_arr_len)) ]}"
            ((color_index+=1))
        fi
        prev_t="$curr_t"
        h_tail=( "${h_atom[@]:1}" ) #1 change to 2 if want exclude timestamp
        echo "${h_atom[0]} ${h_tail[@]}"
    done
fi
set +f #reset glob
printf "%s" "${p_orig}"
