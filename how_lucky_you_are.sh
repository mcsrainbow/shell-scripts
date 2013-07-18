#!/bin/sh

function get_red_balls(){
  RED_BALL=`expr $RANDOM % 33 + 1`
  for EXISTING_BALL in `cat red_balls.txt` ; do
    if [ $EXISTING_BALL == $RED_BALL ] ; then
      return
    fi
  done
  echo RED: $RED_BALL
  echo $RED_BALL >> red_balls.txt
}

function get_all_red_balls(){
  RED_BALL_NUMBER=`wc -l red_balls.txt | awk '{print $1}'`
  MAX_NUMBER=6
  while [[ ${RED_BALL_NUMBER} -lt ${MAX_NUMBER} ]]
  do
    get_red_balls
    RED_BALL_NUMBER=`wc -l red_balls.txt | awk '{print $1}'`
  done
}

function get_blue_ball(){
  BLUE_BALL=`expr $RANDOM % 16 + 1`
  echo BLUE: $BLUE_BALL
  echo $BLUE_BALL > blue_ball.txt
}

function format_numbers(){
  cat red_balls.txt | sort -n >> formated_numbers.txt
  cat blue_ball.txt >> formated_numbers.txt
  cat /dev/null > red_balls.txt
}

MY_BALLS_MD5SUM=`md5sum my_balls.txt | awk '{print $1}'`
FORMATED_NUMBERS_MD5SUM=`md5sum formated_numbers.txt | awk '{print $1}'`
TIMES=1
while true
do
   get_all_red_balls
   get_blue_ball
   format_numbers
  if [ $MY_BALLS_MD5SUM == $FORMATED_NUMBERS_MD5SUM ]; then
    echo "You finally get 500W RMB after you buy this $TIMES times!"
    exit
  fi
  TIMES=`expr $TIMES + 1`
  echo You have tried $TIMES times.
  cat /dev/null > formated_numbers.txt
done
