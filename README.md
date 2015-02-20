# Vagrant IPython notebook install

This is a work-in-progress repository containing a
[vagrant](https://www.vagrantup.com/) configuration for an
[IPython](https://ipython.org)-based compute machine.

## Installation

1. [Get vagrant installed and
   working](http://docs.vagrantup.com/v2/getting-started/index.html).
2. Clone this repo:
```console
$ git clone https://github.com/rjw57/vagrant-ipython
$ cd vagrant-ipython
```
3. Start the virtual machine:
```console
$ vagrant up
```
4. Go to http://localhost:9888/ and start playing.

## Troubleshooting

### There's nothing at localhost:9888

Make sure IPython is running. Log into the machine via ``vagrant ssh`` and
check the status of the IPython server:
```console
$ sudo initctl status ipython-notebook
```
If it's not started, try:
```console
$ sudo initctl start ipython-notebook
```
If there's still no joy, look at the log file at
``/var/logs/upstart/ipython-notebook.log``.

### The MATLAB example doesn't work

The MATLAB magic is specific to my machine at work. It'll probably need a fair
bit of tweaking for other setups. Sorry but I'm not a big MATLAB user.

