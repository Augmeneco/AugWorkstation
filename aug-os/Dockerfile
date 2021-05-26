FROM archlinux

RUN echo 'Server = https://mirror.yandex.ru/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

RUN pacman -Syu --noconfirm
RUN pacman -S --noconfirm xorg-server xfce4 xfce4-goodies
RUN pacman -S --noconfirm konsole sudo fakeroot binutils neofetch noto-fonts

#WPS OFFICE
RUN pacman -S --noconfirm git && \
    cd /tmp && \
    git clone https://aur.archlinux.org/wps-office.git && \
    cd wps-office && \
    chmod -R 777 /tmp/wps-office && \
    sudo -u nobody makepkg -s --noconfirm
RUN cd /tmp/wps-office && \
    pacman -U --noconfirm ./*.pkg.tar.zst

#WPS OFFICE FONTS
RUN cd /tmp && \
    git clone https://aur.archlinux.org/ttf-wps-fonts.git && \
    cd ttf-wps-fonts && \
    chmod -R 777 /tmp/ttf-wps-fonts && \
    sudo -u nobody makepkg -s --noconfirm
RUN cd /tmp/ttf-wps-fonts && \
    pacman -U --noconfirm ./*.pkg.tar.zst

RUN pacman -S firefox

ENV LANG ru_RU.UTF-8
RUN echo en_EN.UTF-8 UTF-8 > /etc/locale.gen
RUN echo ru_RU.UTF-8 UTF-8 >> /etc/locale.gen

CMD ["startxfce4"]