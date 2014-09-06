require "errbit_lighthouse_plugin/version"
require 'errbit_lighthouse_plugin/error'
require 'errbit_lighthouse_plugin/issue_tracker'
require 'errbit_lighthouse_plugin/rails'

module ErrbitLighthousePlugin
  def self.root
    File.expand_path '../..', __FILE__
  end
end

ErrbitPlugin::Registry.add_issue_tracker(ErrbitLighthousePlugin::IssueTracker)
