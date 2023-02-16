#!/bin/bash
USER=ansible
PASS=Secret #INFORM THE PASSWORD
HOME=/home/ansible
LOG=user.log
SSH_KEY_FILE=/home/ansible/.ssh/authorized_keys

echo -ne Creating ansible user...
/usr/sbin/useradd --shell /bin/bash --home $HOME $USER >> $LOG
sleep 1
echo Done

echo -ne Setting Password...
echo "ansible:password" | /usr/sbin/chpasswd >> $LOG
sleep 1
echo Done

echo -ne Updating sudoers..
echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sleep 1
echo Done

echo -ne Setting ssh authorization key...
mkdir -p $HOME/.ssh
chown -R ansible. $HOME/.ssh
chmod 700 $HOME/.ssh
tee $SSH_KEY_FILE << EOF >> $LOG
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDgbSK19Un9nbVQVPb3p9rg6OEJnTU8LqfBJJ2xvhfC3CACnVuygG+juepOkF3iUbZggufZYk70g9QZwVrDQrrp04dS4U9tFWztni7OV1v/R48CXqadzrr42WNi5l6qywfF/cqjpTaf+Nfj0s/41TYRPJEfc8Ffw1wn4fWM9Z10UppXytrOVRXTpkqrZxB+gLOIERMroZuUOuaOJHPfOvT9X22WahhwbJjQX2UL2DVC+BYN51O/O77C/V8Mvhib0ViC7J2X3wxfByVmAwtAv9xyI/HNTlgV3jU+zNgweOFG9P9LRsEQUs7l0KAYDF3l/HTOnARZ+e4s2KlQvzs7/qrIBGlSK3tCP4+vAzU1fH4ut6fZkxzujdwVrnllHbfby/BlSfl1skc7oKtVwlbmRavf3/YCnEI0exDxeBgIGXpZidQ81CFNI9FxI0+6INAVaxjgCvZpjWoXKn5k7RQTxWg4dD3RyeMIhg+ZO3TrXaMTdVUSbCEw/2uKEI0Walarqis= alexandro.silva@BRRIOLN036534
EOF
sleep 1
echo Done
