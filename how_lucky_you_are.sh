#!/bin/bash

# Let's see how lucky you are
# 
# The rule is same as a lottery in China:
# The red balls are between 1 to 33
# The blue ball is between 1 to 16
# A ticket has 6 red balls and 1 blue ball
# If you predict them all you can get 500W RMB
# 
# Just write down your balls in file "my_balls.txt":
# each ball in a single line
# red balls first, from small to large
# then put the blue ball at the bottom line
# 
# Run this script, it will stop when you get the money

function get_red_ball(){
  RED_BALL=`expr $RANDOM % 33 + 1`
  for EXISTING_BALL in `cat red_balls.txt` ; do
    if [ $EXISTING_BALL == $RED_BALL ] ; then
      return
    fi
  done
  echo "RED: $RED_BALL"
  echo $RED_BALL >> red_balls.txt
}

function get_all_red_balls(){
  RED_BALL_NUMBER=`wc -l red_balls.txt | awk '{print $1}'`
  MAX_NUMBER=6
  while [[ ${RED_BALL_NUMBER} -lt ${MAX_NUMBER} ]]
  do
    get_red_ball
    RED_BALL_NUMBER=`wc -l red_balls.txt | awk '{print $1}'`
  done
}

function get_blue_ball(){
  BLUE_BALL=`expr $RANDOM % 16 + 1`
  echo "BLUE: $BLUE_BALL"
  echo $BLUE_BALL > blue_ball.txt
}

function sort_balls(){
  cat red_balls.txt | sort -n >> sorted_balls.txt
  cat blue_ball.txt >> sorted_balls.txt
  cat /dev/null > red_balls.txt
}

MY_BALLS_MD5SUM=`md5sum my_balls.txt | awk '{print $1}'`
TIMES=1
while true
do
  get_all_red_balls
  get_blue_ball
  sort_balls
  SORTED_BALLS_MD5SUM=`md5sum sorted_balls.txt | awk '{print $1}'`
  if [ $MY_BALLS_MD5SUM == $SORTED_BALLS_MD5SUM ]; then
    echo "You finally got 500W RMB after you bought this $TIMES times!"
    exit 0
  fi
  TIMES=`expr $TIMES + 1`
  echo "You have tried $TIMES times."
  cat /dev/null > sorted_balls.txt
done
