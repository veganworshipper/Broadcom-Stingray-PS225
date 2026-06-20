# Helper script for yocto2ubuntu.sh to switch to Ubuntu file system.

dpkg --purge cloud-init
cp /etc/init/ttyAMA0.conf /etc/init/ttyS0.conf
sed 's/ttyAMA0/ttyS0/g' -i /etc/init/ttyS0.conf
adduser --disabled-password --gecos "" lab
echo "lab:lab" | chpasswd
addgroup lab admin
addgroup lab sudo
sed 's/PasswordAuthentication/# PasswordAuthentication/g' -i /etc/ssh/sshd_config
dpkg-reconfigure openssh-server

