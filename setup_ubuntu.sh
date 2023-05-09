#!/bin/sh

#################################
###### Setup Env Start ######
#################################

# for your own home disk
workspace_disk_label="XXXXX"

# for duck DDNS
duckdns_domain="XXXX.duckdns.org"
duckdns_token="XXXXXXX"

# for telegram bot
bot_token='XXXXXX'
bot_chatID='XXXXXXX'
bot_message="Dev Server is on"

#################################
###### Setup Env End ######
#################################

# use e2label to label your ebs first, need to set it again after format
workspace_disk_uuid=$(lsblk -o LABEL,UUID | grep ${workspace_disk_label} | awk -F ' +' '{print $2}')

line="UUID=${workspace_disk_uuid} /home ext4 defaults 0 0"
sudo grep "$line" /etc/fstab || echo "$line" | sudo tee -a /etc/fstab
cp -r ~/.ssh /tmp/
sudo mount -a

if [ ! -d /home/ubuntu ]; then
  sudo mkdir -p /home/ubuntu && sudo chown ubuntu:ubuntu /home/ubuntu && cp -r /tmp/.ssh ~/
fi

rm -rf /tmp/.ssh

# 2 GB swap
sudo dd if=/dev/zero of=/swapfile bs=128M count=16 && \
sudo chmod 600 /swapfile && \
sudo mkswap /swapfile && \
sudo swapon /swapfile

line="/swapfile swap swap defaults 0 0"
sudo grep "$line" /etc/fstab || echo "$line" | sudo tee -a /etc/fstab

# update DDNS
mkdir -p ~/bin
if [ ! -f ~/bin/duck.sh ]; then
  echo "curl \"https://www.duckdns.org/update?domains=${duckdns_domain}&token=${duckdns_token}\"" > ~/bin/duck.sh
  chmod +x ~/bin/duck.sh
fi
~/bin/duck.sh

# install packages
sudo apt update && sudo apt install -y python3.10-venv awscli

# install terraform 
sudo apt update && sudo apt install gpg
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# for chrome remote desktop
sudo apt install -y xfce4
sudo apt install -y xvfb xbase-clients python3-psutil python3-pip libxkbcommon-x11-0 libxss1 libgconf-2-4 libgbm-dev libnss3-dev libasound2-dev libxcomposite-dev libxcursor-dev libxdamage-dev libxi-dev libxtst-dev libpulse-dev xserver-xorg-video-dummy

wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
sudo apt update
sudo apt install -y google-chrome-stable
wget https://dl.google.com/linux/direct/chrome-remote-desktop_current_amd64.deb
sudo dpkg --install chrome-remote-desktop_current_amd64.deb
rm chrome-remote-desktop_current_amd64.deb

# install urlencode
sudo apt install -y gridsite-clients

bot_message=$(urlencode "$bot_message")
if [ ! -f ~/bin/inform_live.sh ]; then
  echo "curl \"https://api.telegram.org/bot$bot_token/sendMessage?chat_id=$bot_chatID&parse_mode=Markdown&text=$bot_message\"" > ~/bin/inform_live.sh
  chmod +x ~/bin/inform_live.sh
fi
~/bin/inform_live.sh

# setup cron
bash -c "echo -e '*/2 * * * * ~/bin/duck.sh >/dev/null 2>&1\n*/15 * * * * ~/bin/inform_live.sh >/dev/null 2>&1' | crontab -"