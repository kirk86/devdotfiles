function install_prerequisites
{
    # update packages
    sudo aptg-get update
    sudo apt-get upgrade
    sudo apt-get dist-ugrade

    # remove unecessary packages
    sudo apt-get autoremove

    # install prerequisites
    sudo apt-get install -y software-properties-common \
         libgraphicsmagick1-dev libfftw3-dev sox libsox-dev \
         libsox-fmt-all

    # install prerequisites - build-essential
    sudo apt-get install -y build-essential gcc g++ curl wget \
         cmake libreadline-dev git-core libqt4-dev libjpeg-dev \
         libpng-dev ncurses-dev imagemagick libzmq3-dev gfortran \
         unzip gnuplot gnuplot-x11
    # libopenblas-dev
}


# install vncserver/viewer
function install_tigervnc
{
    # install minimal gui for vnc/rdp access
    sudo apt-get install xorg lxde-core lxtask lxrandr lxterminal git \
         devscripts lsb-core lsb_release

    mkdir -p ${HOME}/tigervnc && cd ${HOME}/tigervnc
    git clone https://github.com/TigerVNC/tigervnc
    cd tigervnc
    git checkout 044e2b87da7121ef6cbd59e88b101d7d8e282896 \
        -b 044e2b87da7121ef6cbd59e88b101d7d8e282896
    # ln -s contrib/packages/deb/ubuntu-$(lsb_release -a | grep -i codename | cut -f2)/debian
    # just to be sure if lsb_release can not be installed
    ln -s contrib/packages/deb/ubuntu-$(cat /etc/lsb-release | grep -i codename | cut -d= -f2)/debian
    # intall pkgs in order to build tigervnc
    sudo apt install -y $(grep Build-Depends: debian/control | \
                                 sed -e 's/Build-Depends://g' -e 's/([^\)]*)//g' -e 's/,//g')
    # build tigervnc
    chmod a+x debian/rules
    fakeroot debian/rules binary

    # Install deb files while installing depend package with running
    # "apt -f install".
    cd ..
    sudo dpkg -i *.deb || (sudo apt -f install -y; sudo dpkg -i *.deb)
    cd ..

    # create vncuser
    echo "Adding user for tigervncserver with username tigervcnuser";
    sudo adduser tigervncuser;
    # passwd tigervncuser

    read -p "Do you wanna add tigervncuser to sudoers group ? [y/N] " yn
    case $yn in
        Y|y ) sudo usermod -aG sudo tigervncuser;;
        * ) echo "Yes master!"
    esac

    echo "Switching to vncserver user in order to add vncserver password!"
    sudo runuser -l tigervncuser -c tigervncpasswd
    # sudo -H -u tigervncuser bash -c tigervncpasswd

    # run vncserver once to create config files and kill
    echo "Running tigervncserver in order to create config files."
    tigervncserver
    echo "Killing tigervncserver."
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
   sudo apt install -y xrdp
   sudo systemctl enable xrdp
   sudo systemctl restart xrdp

   # finally enable tigervnc
   tigervncserver

   # cleanup
   rm -rf ${HOME}/tigervnc
}

function install_openblas
{
    # Get and build OpenBlas (Torch is much better with a decent Blas)
    cd /tmp/
    rm -rf OpenBLAS
    git clone https://github.com/xianyi/OpenBLAS.git
    cd OpenBLAS
    if [ $(getconf _NPROCESSORS_ONLN) == 1 ]; then
        make NO_AFFINITY=1 USE_OPENMP=0 USE_THREAD=0
    else
        make NO_AFFINITY=1 USE_OPENMP=1
    fi
    RET=$?;
    if [ $RET -ne 0 ]; then
        echo "Error. OpenBLAS could not be compiled";
        exit $RET;
    fi
    sudo make install
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

    read "Do you wanna install miniconda or anaconda ? [y/N]" yn
    case $yn in
        Y|y ) wget https://repo.continuum.io/miniconda/Miniconda2-4.1.11-Linux-x86_64.sh;
              bash Miniconda2-4.1.11-Linux-x86_64.sh;;
        * ) wget https://repo.continuum.io/archive/Anaconda2-4.2.0-Linux-x86_64.sh;
            bash Anaconda2-4.2.0-Linux-x86_64.sh
            exit 0
    esac

    # Add anaconda to your $PATH
    export PATH=$HOME/anaconda/bin:$PATH;

    read "Do you wanna install Theano ?" yn
    case $yn in
        Y|y ) conda install Theano;;
        * ) echo "Yes master!"
            exit 0
    esac

    read "would you like to run tests for Theano now ? [y/n]" yn
    case $yn in
        y|y ) python -c "import theano; theano.test()";;
        * ) echo "yes master!"
            exit 0
    esac

    read "Do you wanna install Torch7 separetely or as part of anaconda ?" yn
    case $yn in
        Y|y ) git clone https://github.com/torch/distro.git ~/torch --recursive;
              cd ~/torch; bash install-deps; ./install.sh;;
        * ) conda install lua=5.2 lua-science -c alexbw
            exit 0
    esac

    read "would you like to run tests for Torch7 now ? [y/n]" yn
    case $yn in
        y|y ) cd ${HOME}/torch; bash ./test.sh;;
        * ) echo "yes master!"
            exit 0
    esac
}
