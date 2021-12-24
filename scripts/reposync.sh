#!/bin/bash

repo_items=(
base,centos/7/os/x86_64
updates,centos/7/updates/x86_64
extras,centos/7/extras/x86_64
centosplus,centos/7/centosplus/x86_64
lux,lux/centos/7
epel,epel/7/x86_64/
docker-ce-stable,docker-ce/centos/7/x86_64/stable
)

repo_path=/var/www/html/repos

for item in ${repo_items[@]};do 
  repo_id=$(echo $item|cut -d, -f1)
  sub_dir=$(echo $item|cut -d, -f2)

  reposync -l -d -m --repoid=$repo_id --download-metadata --norepopath --download_path=$repo_path/$sub_dir

  cd $repo_path/$sub_dir
  if [ -f $repo_path/$sub_dir/comps.xml ];then
    createrepo $repo_path/$sub_dir/ -g comps.xml
  else
    createrepo $repo_path/$sub_dir/
  fi
done
