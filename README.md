
This repository contains a ruby script to check the status of the Travis status of a collection of GitHub repositories, selected by their names.

Some instructions:

- Ruby and the gem travis must be installed (for instance, in Ubuntu):

sudo apt install ruby

sudo apt install ruby-dev

sudo gem install travis -v 1.8.9 --no-rdoc --no-ri

- Once the repository is downloaded, in order to check the repository status, simply run:

ruby recuperarepositorios.rb cuasi

where cuasi denotes the user's github account login.


