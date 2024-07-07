sudo systemctl stop mdatp
systemctl list-units --type=service | grep mdatp
sudo systemctl disable mdatp
#Removed /etc/systemd/system/multi-user.target.wants/mdatp.service.

sudo systemctl status mdatp



