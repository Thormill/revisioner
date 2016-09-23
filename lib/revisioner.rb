require "revisioner/version"
require "revisioner/config"
require "revisioner/importer"
require "revisioner/parser"

module Revisioner
  # Your code goes here...
  REVISION_FAILURE = 0
  REVISION_SUCCESS = 1
  REVISION_NOT_FOUND = 2
  REVISION_DIFFERENCE = 3
end
