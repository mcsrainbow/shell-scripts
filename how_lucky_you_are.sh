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

function check_my_balls(){
  if [ ! -f "my_balls.txt" ] ; then
    echo "The file my_balls.txt does not exist."
    exit 1
  fi
  MY_BALLS_NUMBER=`wc -l my_balls.txt | awk '{print $1}'`
  if [ $MY_BALLS_NUMBER -ne 7 ] ; then
    echo "You need 7 balls in my_balls.txt."
    exit 1
  fi
  for BALL in `cat my_balls.txt`
  do
    echo $BALL | grep "[^1-9]"
    if [ $? -eq 0 ]; then
      echo "BALL: $BALL is not an integer."
      exit 1
    fi
  done
  for BALL in `head -n 6 my_balls.txt`
  do
    if [ $BALL -gt 33 ] ; then
      echo "RED BALL: $BALL is greater than 33."
      exit 1
    fi
  done
  LAST_BALL=`tail -n 1 my_balls.txt`
  if [ $LAST_BALL -gt 16 ] ; then
    echo "BLUE BALL: $LAST_BALL is greater than 16."
    exit 1
  fi
}

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

check_my_balls
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
  echo "You have tried $TIMES times."
  TIMES=`expr $TIMES + 1`
  cat /dev/null > sorted_balls.txt
done
