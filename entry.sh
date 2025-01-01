#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
echo "<h1> This message from PROVIDER VPC: $(hostname -i)</h1>" | sudo tee /var/www/html/index.html

