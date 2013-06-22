require 'capistrano'
require 'capistrano/cli'
require 'helpers'
$LOAD_PATH << File.join(File.dirname(__FILE__), 'lib')
require 'recipes/deploy'
require 'recipes/hooks'
require 'recipes/symlinks'

