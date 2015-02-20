#!/bin/bash
#
# This shell script is run at VM creation time to install the initial set of
# software and configure the machine.
#
# It is run as the "vagrant" user.

# Ensure package db is up to date.
sudo apt-get update

# Install the system python3 packages we desire.
sudo apt-get install -y python3-pip python3-numpy python3-scipy python3-zmq \
	python3-matplotlib

# Configure pip to always use --user when installing
mkdir -p ~/.pip
cat >~/.pip/pip.conf <<EOF
[install]
user = true
EOF

# Add ~/.local/bin to user's path
cat >>~/.bashrc <<EOF
# set PATH so that it includes user's .local/bin if it exists
if [ -d "$HOME/.local/bin" ]; then
	PATH="$HOME/.local/bin:$PATH"
fi
EOF

# Install the custom Python packages from PyPI.
pip3 install jsonschema tornado jinja2
pip3 install terminado # <= for terminal support in IPython notebook
pip3 install 'ipython==3.0.0rc1'

# If there's a requirements.txt in the vagrant directory, also pip install that.
if [ -f "/vagrant/requirements.txt" ]; then
	pip3 install -r "/vagrant/requirements.txt"
fi

# Create some convenient links in the user's home dir.
ln -s "/vagrant/notebooks" "~/notebooks"

# Create an upstart job for IPython. The following will have to be changed in
# the systemd world.
sudo tee /etc/init/ipython-notebook.conf >/dev/null <<EOF
description "IPython notebook for vagrant user"

start on runlevel [2345]
stop on runlevel [016]
respawn limit 10 5
chdir /vagrant/notebooks/
exec sudo -u vagrant /home/vagrant/.local/bin/ipython notebook --no-browser \
	--ip=0.0.0.0 --port 8888 --ipython-dir=/vagrant/ipython/
EOF

# Start upstart job.
sudo initctl start ipython-notebook

