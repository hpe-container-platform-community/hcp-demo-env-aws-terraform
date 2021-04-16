#!/usr/bin/env bash

set -e # abort on error
set -u # abort on undefined variable

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source "$SCRIPT_DIR/../../scripts/variables.sh"

ssh -o StrictHostKeyChecking=no -i "${LOCAL_SSH_PRV_KEY_PATH}" -T centos@${CTRL_PUB_IP} <<-SSH_EOF
	set -e

	[[ -d /home/centos/.pyenv ]] && exit 0    # we have already been installed

	sudo yum install -y -q gcc gcc-c++ make git patch openssl-devel zlib zlib-devel readline-devel sqlite-devel bzip2-devel libffi-devel
	git clone git://github.com/yyuu/pyenv.git ~/.pyenv
	echo 'export PATH="\$HOME/.pyenv/bin:\$PATH"' >> ~/.bashrc
	echo 'eval "\$(pyenv init -)"' >> ~/.bashrc
	source ~/.bashrc
	pyenv install 3.6.10

	git clone https://github.com/pyenv/pyenv-virtualenv.git \$(pyenv root)/plugins/pyenv-virtualenv
	echo 'eval "\$(pyenv virtualenv-init -)"' >> ~/.bashrc
	source ~/.bashrc

	pyenv virtualenv 3.6.10 my-3.6.10
	pyenv activate my-3.6.10

	pip install --upgrade --quiet pip
	pip install --upgrade --quiet hpecp

SSH_EOF
