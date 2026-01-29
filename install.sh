#!/bin/bash

sudo apt update; sudo apt upgrade -y
# sudo reboot
# reconnect

sudo apt install -y gcc-12 g++-12 build-essential pkg-config yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev nasm neofetch
wget https://developer.download.nvidia.com/compute/cuda/12.8.0/local_installers/cuda_12.8.0_570.86.10_linux.run
sudo sh ./cuda_12.8.0_570.86.10_linux.run

# Add cuda to path

# Driver:   Installed
# Toolkit:  Installed in /usr/local/cuda-12.8/
# 
# Please make sure that
#  -   PATH includes /usr/local/cuda-12.8/bin
#  -   LD_LIBRARY_PATH includes /usr/local/cuda-12.8/lib64, or, add /usr/local/cuda-12.8/lib64 to /etc/ld.so.conf and run ldconfig as root

export PATH="$PATH:/usr/local/cuda-12.8/bin" # Add this to the bashrc o zshrc to persist the change
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/cuda-12.8/lib64" # Add this to the bashrc o zshrc to persist the change

git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
cd nv-codec-headers && sudo make install && cd
git clone https://git.ffmpeg.org/ffmpeg.git ffmpeg/
cd ffmpeg && ./configure --enable-nonfree --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --disable-static --enable-shared
make -j 8
sudo make install
sudo ldconfig
cd

sudo apt install -y inotify-tools nginx libnginx-mod-rtmp libxml2-utils
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

chmod +x configure.sh
sudo ./configure.sh
