#!/usr/bin/env bash
set -e

function print_message
{
    echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
    echo ";;        $1                               ;;"
    echo ";;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;"
}

function checkupdates_archlinux
{
    # checks if archlinux is up to date
    if [[ -n $(checkupdates) ]]; then
        print_message "It seems that your system is not up to date."
        print_message "It is recommended to update your system before going any further."
        read -p "Continue updating and installing prerequisites ? [y/N] " yn
            case $yn in
                Y|y ) install_prerequisites;;
                * ) echo "Installation aborted."
                    echo "Relaunch this script after updating your system with 'pacman -Syu'."
                    exit 0
            esac
    fi
}

function install_prerequisites
{
    # update packages
    sudo pacman -Syu

    # install prerequisites
    sudo pacman -Sy base-devel

    print_message "Archlinux installation"
    checkupdates_archlinux
    sudo pacman -S --quiet --noconfirm --needed \
         cmake curl readline ncurses git \
         gnuplot unzip libjpeg-turbo libpng \
         imagemagick graphicsmagick fftw sox zeromq \
         qt4 qtwebkit xorg-server xorg-init || exit 1
    pacman -Sl multilib &>/dev/null
    if [[ $? -ne 0 ]]; then
        gcc_package="gcc"
    else
        gcc_package="gcc-multilib"
    fi
    sudo pacman -S --quiet --noconfirm --needed \
         ${gcc_package} gcc-fortran || exit 1
    # if openblas is not installed yet
    pacman -Qs openblas &> /dev/null
    if [[ $? -ne 0 ]]; then
        install_openblas_AUR || true
    else
        print_message "OpenBLAS is already installed"
    fi
}

# install vncserver/viewer
function install_tigervnc
{
    # install minimal gui for vnc/rdp access
    print_message "Installing minimal gui."
    pacman -S gamin LXDE
    chmod +x ${HOME}/.xinitrc
    echo "exec startlxde" >> ${HOME}/.xinitrc
    sudo pacman -S tigervnc

    # create vncuser
    print_message "Adding user for tigervncserver with username tigervcnuser"
    useradd -m -G wheel tigervncuser
    # passwd tigervncuser

    read -p "Do you wanna add tigervncuser to sudoers group ? [y/N] " yn
    case $yn in
        Y|y ) sudo usermod -aG sudo tigervncuser;;
        * ) echo "Yes master!"
    esac

    print_message "Switching to vncserver user in order to add vncserver password!"
    su - tigervncuser -c tigervncpasswd
    # sudo -H -u tigervncuser bash -c tigervncpasswd

    # run vncserver once to create config files and kill
    print_message "Running tigervncserver in order to create config files."
    tigervncserver
    print_message "Killing tigervncserver."
    tigervncserver -kill :1

    cp ${HOME}/.vnc/xstartup ${HOME}/.vnc/xstartup-old

   cat <<EOF > ${HOME}/.vnc/xstartup
#!/bin/sh
#
# Uncomment the following two lines for normal desktop:
# unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
# exec /etc/X11/xinit/xinitrc
#
[ -x /etc/vnc/xstartup ] && exec /etc/vnc/xstartup
[ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
xsetroot -solid grey
vncconfig -iconic &
x-terminal-emulator -geometry 80x24+10+10 -ls -title "$VNCDESKTOP Desktop" &
startlxde &
EOF

   # install and run xrdp server
   pacman -Sy xrdp
   sudo systemctl enable xrdp
   sudo systemctl restart xrdp
   sudo systemctl start xrdp

   # finally enable tigervnc
   print_message "Enabling tigervncserver."
   tigervncserver

   # cleanup
   rm -rf ${HOME}/tigervnc
}

function install_openblas
{
    # build and install an OpenBLAS package for Archlinux
    cd /tmp && \
        curl https://aur.archlinux.org/cgit/aur.git/snapshot/openblas-lapack.tar.gz | tar zxf - && \
        cd openblas-lapack
    makepkg -csi --noconfirm
    RET=$?;
    if [ $RET -ne 0 ]; then
        echo "Error. OpenBLAS could not be installed";
        exit $RET;
    fi
}

function install_anaconda
{
    # download and install conda
    cd ${HOME}

    read -p "Do you wanna install miniconda or anaconda ? [y/N] " yn
    case $yn in
        Y|y ) wget https://repo.continuum.io/miniconda/Miniconda2-4.1.11-Linux-x86_64.sh
              bash Miniconda2-4.1.11-Linux-x86_64.sh
              source ${HOME}/.bashrc
              read -p "Do you wanna install Theano ? [y/N] " yn
              case $yn in
                  Y|y ) pip install Theano;;
                  * ) print_message "Yes master!"
              esac;;
        * ) wget https://repo.continuum.io/archive/Anaconda2-4.2.0-Linux-x86_64.sh
            bash Anaconda2-4.2.0-Linux-x86_64.sh
            source ${HOME}/.bashrc
            read -p "Do you wanna install Theano ? [y/N] " yn
            case $yn in
                Y|y ) conda install Theano;;
                * ) print_message "Yes master!"
            esac
    esac

    # Add anaconda to your $PATH
    # echo "Adding anaconda to your path!"
    # echo export PATH=$HOME/anaconda/bin:$PATH >> ${HOME}/.bashrc


    read -p "Would you like to run the tests for Theano now ? [y/n] " yn
    case $yn in
        y|y ) conda install nose
              pip install nose-parameterized
              sudo apt-get install -y -f graphviz
              conda install graphviz
              conda install pydot
              python -c "import theano; theano.test()";;
        * ) print_message "Installing pckgs required to run tests later."
            conda install nose
            pip install nose-parameterized
            sudo pacman -S graphviz
            conda install graphviz
            conda install pydot
    esac

    read -p "Do you wanna install Torch7 separetely or as part of anaconda ? [y/N] " yn
    case $yn in
        Y|y ) git clone https://github.com/torch/distro.git ~/torch --recursive
              cd ~/torch; bash install-deps; ./install.sh
              read -p "would you like to run the tests for Torch7 now ? [y/n] " yn
              case $yn in
                  Y|y ) cd ${HOME}/torch; bash ./test.sh;;
                  * ) print_message "yes master!"
              esac;;
        * ) print_message "Installing Torch7 as part of conda."
            conda install lua=5.2 lua-science -c alexbw
    esac
}

function cleanup
{
    print_message "Cleaning up!"
    rm -rf /tmp/OpenBLAS;
}

install_prerequisites 2>logs.txt
install_tigervnc 2>logs.txt
install_openblas 2>logs.txt
install_anaconda 2>logs.txt
cleanup 2>logs.txt
