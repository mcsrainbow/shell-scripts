#!/usr/bin/expect
set timeout 5
set host [lindex $argv 0]
set user [lindex $argv 1]
set oldpass [lindex $argv 2]
set newpass [lindex $argv 3]

spawn ssh -tq ${user}@${host}
#spawn ssh ${user}@${host}
expect "ssword:"
send "${oldpass}\r"
expect "${user}@"
send "passwd\r"
expect "current"
send "${oldpass}\r"
expect {
  "New password:" {
    send "${newpass}\r"
    expect {
      "BAD PASSWORD" {
      exit 1 }
      "Password unchanged" {
      exit 1 }
      "Authentication token manipulation error" {
      exit 1 }
      "Retype new password:" {
        send "${newpass}\r"
        expect "${user}@"
        send "exit\r"
      exit 0 }
      eof {
      exit 0 }
    }
  }
  "wait longer" {
  exit 1 }
}
