#!/bin/bash
function bubble_sort()
{
    declare -a xx
    x=${@}
    local sum=0
    for i in ${x[@]}
    do
        xx[$sum]=$i
        sum=$[$sum + 1]
    done
    n=$[$sum - 1]
    for((;n>0;n--))
    do
        for((i=0;i<n;i++))
        do
            ii=$[$i + 1]
            if [ ${xx[$ii]} -lt ${xx[$i]} ]; then
                tmp=${xx[$ii]}
                xx[$ii]=${xx[$i]}
                xx[$i]=$tmp
            fi
        done
    done
    echo ${xx[@]}
}

function get_random_array()
{
    for((i=0;i<$1;i++))
    do
        echo $[$RANDOM%33 +1]
    done
}

declare -a blues
red=0
sum=0
for i in `cat my_balls.txt`
do
    if [ $sum -lt 6 ]; then
        blues[$sum]=$i
    else
        red=$i
    fi
    sum=$[$sum + 1]
done
if [ $sum != 7 ]; then
    echo "file format error!"
    exit 0
fi
echo "blues :"${blues[@]}
echo "red :"$red
sorted_blues=$(bubble_sort ${blues[@]})
echo "==================="
echo "blues :"${sorted_blues[@]}
echo "red :"$red

#====================
#Begin to produce random array
#====================
declare -a random_blues
declare -a sorted_random_blues
t=0
flag=1
while(($flag==1))
do
    random_blues=$(get_random_array 6)
    sorted_random_blues=$(bubble_sort ${random_blues[@]})
    random_red=$[$RANDOM%16 + 1]

    if [ $[$t%10000] -eq 0 ]; then
        echo $t
    fi

    if [ $random_red -eq $red ] && [ "$sorted_random_blues" == "$sorted_blues" ]; then
        flag=0;
        echo $sorted_random_blues
        echo "You win after $t times!"
    fi
    t=$[$t + 1]
done
