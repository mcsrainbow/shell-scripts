#!/bin/env python

# Description: rsync and clean based on earliest_rsync_succeeded_date
# Author: Damon Guo

import os
import sys
import subprocess
from datetime import datetime
import time
import yaml
from bisect import bisect

def get_sftp_user(sftp_user_conf,rsync_src_dir):
    sftp_user_list = []
    with open(sftp_user_conf, 'r') as f:
        for line in f:
            if rsync_src_dir in line:
              sftp_user = line.split(':')[0]
              sftp_user_list.append(sftp_user)

    return sftp_user_list

def rsync_data(rsync_src_dir,rsync_dst_dir,rsync_user,sftp_user_conf,sftp_prod_ip,timeline_yaml):
    sftp_user_list = get_sftp_user(sftp_user_conf,rsync_src_dir)
    with open(timeline_yaml) as f:
        data_dict = yaml.load(f)
        for user in sftp_user_list:
            date_str = datetime.now().strftime("%Y%m%d")
            rsync_cmd_str = "/usr/bin/rsync --timeout=10 --delete --log-file={0}/logs/rsync.{1}.log -ravz {0}/{2} {3}@{4}:{5}/{2}".format(rsync_src_dir,date_str,user,rsync_user,sftp_prod_ip,rsync_dst_dir)
            print("INFO: Running command: {0}".format(rsync_cmd_str))
            rsync_cmd = subprocess.Popen(rsync_cmd_str, shell=True, executable=shell)
            (stdout, stderr) = rsync_cmd.communicate()
            if rsync_cmd.returncode == 0:
                succeeded_timestamp = time.time()
                if not data_dict['rsync_timeline_succeeded'].has_key(user):
                    data_dict['rsync_timeline_succeeded'][user] = [succeeded_timestamp]
                else:
                    data_dict['rsync_timeline_succeeded'][user].append(succeeded_timestamp)

    if len(data_dict['rsync_timeline_succeeded']) >= len(sftp_user_list):
        with open(timeline_yaml, 'w') as f:
            yaml.dump(data_dict, f, default_flow_style=False)
    else:
        print("ERROR: Incorrect data in {0}: data_dict_key_num:{1} < sftp_user_num:{2}".format(timeline_yaml,len(data_dict['rsync_timeline_succeeded']),len(sftp_user_list)))
        return False

    return True

def get_earliest_rsync_succeeded_timestamp(user,file_mtime,timeline_yaml):
    with open(timeline_yaml) as f:
        data_dict = yaml.load(f)
        if data_dict['rsync_timeline_succeeded'].has_key(user):
            data_dict['rsync_timeline_succeeded'][user].sort()
            index_num = bisect(data_dict['rsync_timeline_succeeded'][user], file_mtime)
            return data_dict['rsync_timeline_succeeded'][user][index_num]

    return False

def clean_data(keep_days,rsync_src_dir,sftp_user_conf,timeline_yaml):
    keep_seconds = keep_days * 86400
    now_timestamp = time.time()

    sftp_user_list = get_sftp_user(sftp_user_conf,rsync_src_dir)
    sftp_user_file_dict = {}
    for user in sftp_user_list:
        sftp_user_file_dict[user] = []
        path = "{0}/{1}".format(rsync_src_dir,user)
        for root, dirs, files in os.walk(path):
            for file_name in files:
                sftp_user_file_dict[user].append(os.path.join(root,file_name))

    for sub_dir in sftp_user_file_dict:
        for file_path in sftp_user_file_dict[sub_dir]:
            file_stat = os.stat(file_path)
            earliest_rsync_succeeded_timestamp = get_earliest_rsync_succeeded_timestamp(user,file_stat.st_mtime,timeline_yaml)
            if isinstance(earliest_rsync_succeeded_timestamp, float):
                earliest_rsync_succeeded_date = datetime.fromtimestamp(earliest_rsync_succeeded_timestamp).strftime("%Y-%m-%d_%H:%M:%S")
                if now_timestamp > earliest_rsync_succeeded_timestamp + keep_seconds:
                    os.remove(file_path)
                    print('''INFO: Found earliest_rsync_succeeded_date: {0} older than {1} days. Deleted {2}'''.format(earliest_rsync_succeeded_date,keep_days,file_path))

    return True

def main():
    rsync_src_dir = "/opt/sftp"
    rsync_dst_dir = "/opt/sftp"
    rsync_user = "rsync_user"
    sftp_user_conf = "/etc/passwd"
    sftp_prod_ip = "10.1.2.3"
    timeline_yaml = "{0}/logs/rsync_timeline_succeeded.yml".format(rsync_src_dir)
    keep_days = 14

    if not os.path.isfile(timeline_yaml) or os.stat(timeline_yaml).st_size == 0:
        with open(timeline_yaml, "w") as f:
            f.write("rsync_timeline_succeeded: {}")

    if rsync_data(rsync_src_dir,rsync_dst_dir,rsync_user,sftp_user_conf,sftp_prod_ip,timeline_yaml):
        clean_data(keep_days,rsync_src_dir,sftp_user_conf,timeline_yaml)
        return 0
    else:
        return 2

if __name__ == '__main__':
    sys.exit(main())
