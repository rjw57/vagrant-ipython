#!/bin/bash
#
# This shell script is run at VM creation time to install the initial set of
# software and configure the machine.
#
# It is run as the "vagrant" user.

# Ensure package db is up to date.
sudo apt-get update

# Install the system python3 packages we desire.
sudo apt-get install -y python3-pip python3-numpy python3-scipy python3-zmq

# Install the custom Python packages from PyPI.
pip3 install --user jsonschema tornado jinja2
pip3 install --user terminado # <= for terminal support in IPython notebook
pip3 install --user 'ipython==3.0.0rc1'

# Create an upstart job for IPython. The following will have to be changed in
# the systemd world.
sudo tee /etc/init/ipython-notebook.conf >/dev/null <<EOF
description "IPython notebook for vagrant user"

start on runlevel [2345]
stop on runlevel [016]
respawn limit 10 5
script
	exec sudo -u vagrant /home/vagrant/.local/bin/ipython notebook --no-browser \
	       	--ip=0.0.0.0 --port 8888 --ipython-dir=/vagrant/ipython/
end script
EOF

# Start upstart job.
sudo initctl start ipython-notebook

