#!/usr/bin/env bash

m3u8_url=$1
m3u8_dir=$2
parallel=10

if [ ! $m3u8_url ]; then
    echo "usage ./m3u8_download.sh url dir "
    exit 0
fi

if [ ! $m3u8_dir ]; then
    m3u8_dir=xx
fi

echo "m3u8 url was: "${m3u8_url}
mkdir -p ${m3u8_dir}
cd ${m3u8_dir}

echo "download m3u8..."
wget ${m3u8_url}
echo "download m3u8 done"

# match 
m3u8_base_url=${m3u8_url%/*}"/"
m3u8_file_name=${m3u8_url##*/}
m3u8_host_url=$(echo "$m3u8_url" | grep -P "https?://.*?/" -o)
echo "m3u8 http dir: ${m3u8_base_url}"
echo "m3u8 file name: ${m3u8_file_name}"
echo "m3u8 host url: ${m3u8_host_url}"

sub_dir=""

n=1
for line in `cat ${m3u8_file_name}`
do
if [ `echo ${line} | grep -c "\.ts$"` -eq '1' ]; then
    echo "find ts url: ${line}"
    if [ `echo ${line} | grep -c "http://"` -eq '1' ] || [ `echo ${line} | grep -c "https://"` -eq '1' ]; then
        ts_uri=${line}
    elif [ ${line:0:1} = "/" ]; then
        ts_uri="${m3u8_host_url}${line:1}"
    else
        ts_uri=${m3u8_base_url}${line}
        if [ -z ${sub_dir} ]; then
            echo "mk subdir: "${sub_dir}
            sub_dir=${line%/*}
            mkdir -p $sub_dir
            cd $sub_dir
        fi
    fi
    
    echo "ts url: ${ts_uri}"
    array[$n]=$ts_uri
    b=$(( $n % $parallel ))
    if [ $b -eq 0 ];then
        n=1
        for url in ${array[@]}
        do
            wget $url &
        done
        wait $!
    else
        ((n+=1))
    fi
    #wget $ts_uri
fi
done

for((i=1; i<$n; i++))
do
    wget -q ${array[i]}
done
