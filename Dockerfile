FROM ubuntu:20.04

ARG UID=1000
ARG GID=1000

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
        bc \
        build-essential \
        cmake \
        e2fsprogs \
        libext2fs-dev \
        libzstd-dev \
        libpcre++-dev \
        zlib1g-dev \
        sudo \
        nano \
        tmux && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create a user named `user` with sudo permission
RUN apt -y install sudo nano
RUN groupadd -g $GID -o user
RUN useradd -m -o -u ${UID} -g ${GID} -s /bin/bash user
RUN echo "user:user" | chpasswd
RUN echo "user    ALL=(ALL:ALL) ALL" >> /etc/sudoers

# TMUX for multiple terminals in docker (https://tmuxcheatsheet.com/)
RUN apt -y install tmux
RUN su user
RUN echo "set-option -g default-shell /bin/bash" > $HOME/.tmux.conf