# frozen_string_literal: true

require "terraspace_vcs_gitlab/autoloader"
TerraspaceVcsGitlab::Autoloader.setup

require "json"
require "memoist"

module TerraspaceVcsGitlab
  class Error < StandardError; end
end

require "terraspace"
Terraspace::Cloud::Vcs.register(
  name: "gitlab",
)
