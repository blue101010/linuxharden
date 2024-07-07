echo "Package: mdatp" | sudo tee /etc/apt/preferences.d/mdatp-blacklist
echo "Pin: release *" | sudo tee -a /etc/apt/preferences.d/mdatp-blacklist
echo "Pin-Priority: -1" | sudo tee -a /etc/apt/preferences.d/mdatp-blacklist