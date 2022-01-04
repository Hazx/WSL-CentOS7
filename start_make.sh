#!/bin/bash

base_img="centos:7.9.2009"

if [[ $(id -u) -ne 0 ]];then
    echo "必须在root账户下运行，请尝试使用 sudo -i 切换账户。"
    exit 1
fi
# 构建 Dockerfile
cat <<EOF >> ./Dockerfile
FROM ${base_img}
ADD script /script.sh
RUN chmod +x /script.sh && /script.sh
CMD /usr/sbin/init
EOF

# 构建镜像
docker pull ${base_img}
docker build -t hazx_make_tmp:wslcentos .
if [ "$?" != 0 ];then
    exit 1
fi
docker run -d --privileged --name save_make hazx_make_tmp:wslcentos /usr/sbin/init
docker exec save_make localedef -c -f UTF-8 -i zh_CN zh_CN.utf8
docker stop save_make
docker export -o save_make.tar save_make
mkdir imagebase
tar xvf save_make.tar -C ./imagebase/
cd imagebase
rm -f ./script.sh
rm -f ../rootfs.tar.gz
tar zcvf ../rootfs.tar.gz ./*
cd ..

# 清理
docker rm -f save_make
# docker rmi ${base_img}
docker rmi hazx_make_tmp:wslcentos
rm -fr ./imagebase
rm -f ./save_make.tar
rm -f ./Dockerfile

echo -e "\nWSL镜像制作完毕，rootfs.tar.gz 文件即为所需。\n"