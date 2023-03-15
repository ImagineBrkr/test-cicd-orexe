#!/bin/bash
sudo apt update
sudo apt install -y apache2
sudo systemctl enable apache2
sudo apt install -y stress
sudo apt install -y ansible