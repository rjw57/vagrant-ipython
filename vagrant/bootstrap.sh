#!/bin/bash
#
# This shell script is run at VM creation time to install the initial set of
# software and configure the machine.
#
# It is run as the "vagrant" user. It attempts to be roughly idempotent to
# allow repeated execution on the same machine without changing anything.

# Ensure package db is up to date.
sudo apt-get update

# Install the system python3 packages we desire.
sudo apt-get install -y \
	git git-doc vim \
	python3-pip python3-numpy python3-scipy python3-zmq python3-matplotlib

# Install blas, etc development files to allow building some scikit modules
# from source.
sudo apt-get install -y libblas-dev libatlas-dev gfortran

# If we have MATLAB available, add a wrapper script.
if [ -d "/tools/apps/matlab" ]; then
	sudo tee /usr/bin/matlab >/dev/null <<EOF
#!/bin/bash
matlabversion=R2014a
matlab=/tools/apps/matlab/matlab\$matlabversion/bin/matlab
exec \$matlab "\$@"
EOF
	sudo chmod +x /usr/bin/matlab
fi

# The following adds specific lines of configuration to dotfiles in the user's
# home directory if said line has not yet been added. We do this in a very
# hacky manner which should not be viewed as an exemplar.

# Configure pip to always use --user when installing
mkdir -p ~/.pip
touch ~/.pip/pip.conf
grep -q 3d88c3acd6246c5ddb284cf431d9d5fcded9eed0 ~/.pip/pip.conf || cat >>~/.pip/pip.conf <<EOF
# MAGIC:3d88c3acd6246c5ddb284cf431d9d5fcded9eed0
[install]
user = true
EOF

# Add ~/.local/bin to user's path
touch ~/.bashrc
grep -q 79a432934a63e16cbf96866835c5d8aff103abcd ~/.bashrc || cat >>~/.bashrc <<EOF
# MAGIC:79a432934a63e16cbf96866835c5d8aff103abcd
# set PATH so that it includes user's .local/bin if it exists
if [ -d "\$HOME/.local/bin" ]; then
	PATH="\$HOME/.local/bin:\$PATH"
fi
EOF

# Create some convenient links in the user's home dir.
if [ ! -e "$HOME/notebooks" ]; then
	ln -s "/vagrant/notebooks" "$HOME/notebooks"
fi
if [ ! -e "$HOME/.ipython" ]; then
	# NB: It can be very important that this link is present since IPython
	# kernels often try to install their configuration into this directory.
	ln -s "/vagrant/ipython" "$HOME/.ipython"
fi

# If we've got a custom provision script, run it.
if [ -f "/vagrant/notebooks/setup.sh" ]; then
	/bin/bash "/vagrant/notebooks/setup.sh"
fi

# Install the custom Python packages from PyPI.
pip3 install jsonschema 'tornado>=4.0' jinja2
pip3 install terminado # <= for terminal support in IPython notebook
pip3 install 'ipython==3.0.0rc1'

# If there's a requirements.txt in the vagrant directory, also pip install that.
if [ -f "/vagrant/notebooks/requirements.txt" ]; then
	pip3 install -r "/vagrant/notebooks/requirements.txt"
fi

# Create an upstart job for IPython. The following will have to be changed in
# the systemd world. Output from the IPython process is logged to
# /var/log/upstart/ipython-notebook.log. Note that we intentionally let $HOME
# be expanded at file creation time since $HOME isn't defined when upstart
# starts the job.
sudo tee /etc/init/ipython-notebook.conf >/dev/null <<EOF
# Launch IPython at system boot
#

description "IPython notebook for vagrant user"

start on runlevel [2345]
stop on runlevel [!2345]

respawn
respawn limit 10 5

chdir /vagrant/notebooks/
console log
setuid vagrant
exec $HOME/.local/bin/ipython notebook --no-browser \
	--ip=0.0.0.0 --port 8888 --ipython-dir=/vagrant/ipython/
EOF

# Start upstart job. Allow this to fail since IPython may already be running.
sudo initctl start ipython-notebook || \
	echo "Starting IPython failed. (It may already be running.)" >&2

