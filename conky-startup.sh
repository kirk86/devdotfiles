sleep 20s
killall conky
cd "/home/$(whoami)/.conky/Green Apple Desktop"
conky -c "/home/$(whoami)/.conky/Green Apple Desktop/conky_seamod" &
