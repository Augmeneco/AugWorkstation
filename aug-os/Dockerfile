FROM archlinux

RUN echo 'Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

RUN pacman -Syu --noconfirm
RUN pacman -Sy --noconfirm xorg-server xfce4 xfce4-goodies
RUN pacman -Sy --noconfirm konsole sudo fakeroot binutils neofetch noto-fonts
RUN pacman -Sy --noconfirm gst-plugins-ugly ttf-dejavu ttf-liberation ttf-carlito

#ONLYOFFICE
RUN pacman -S --noconfirm git && \
    cd /tmp && \
    git clone https://aur.archlinux.org/onlyoffice-bin.git && \
    cd onlyoffice-bin && \
    chmod -R 777 /tmp/onlyoffice-bin && \
    sudo -u nobody makepkg -s --noconfirm
RUN cd /tmp/onlyoffice-bin && \
    pacman -U --noconfirm ./*.pkg.tar.zst

RUN pacman -Sy --noconfirm firefox vlc kate gimp thunderbird

ENV LANG ru_RU.UTF-8
RUN echo en_US.UTF-8 UTF-8 > /etc/locale.gen
RUN echo ru_RU.UTF-8 UTF-8 >> /etc/locale.gen
COPY ru_RU /usr/share/i18n/locales
RUN locale-gen
RUN echo "LANG=ru_RU.UTF-8" > /etc/locale.conf

CMD ["startxfce4"]
