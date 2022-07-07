require "gitlab"

module TerraspaceVcsGitlab
  class Interface
    extend Memoist
    include Terraspace::Cloud::Vcs::Interface

    def comment(body)
      return unless gitlab_token?
      return unless ENV['CI_PIPELINE_SOURCE'] == 'merge_request_event'

      mr_number = pr_number
      logger.debug "Adding comment to full_repo #{full_repo} mr_number #{mr_number}"
      project = client.project(ENV['CI_PROJECT_PATH'])
      merge_request = ENV['CI_MERGE_REQUEST_IID']

      # https://www.rubydoc.info/gems/gitlab/Gitlab/Client/Notes
      # TODO handle pagination
      # TODO are we allow to post comment on public full_repo without need the permission?
      notes = client.merge_request_notes(project.id, mr_number)
      found_note = notes.find do |note|
        note.body.starts_with?(MARKER)
      end

      if found_note
        client.edit_merge_request_note(project.id, merge_request, found_note.id, body) unless found_note.body == body
      else
        client.create_merge_request_note(project.id, merge_request, body)
      end
    # Edge cases:
    #   token is not valid
    #   token is not right full_repo
    rescue Gitlab::Error::Unauthorized => e
      logger.info "WARN: #{e.message}. Unable to create merge request comment. Please double check your gitlab token"
    rescue Gitlab::Error::Forbidden => e
      logger.info "WARN: #{e.message}. Unable to create merge request comment. The token does not have the permission. Please double check your gitlab token"
    end

    def client
      Gitlab.configure do |config|
        config.endpoint       = 'https://gitlab.com/api/v4'
        config.private_token  = ENV['GITLAB_TOKEN']
      end
      Gitlab.client
    end
    memoize :client

    def gitlab_token?
      if ENV['GITLAB_TOKEN']
        true
      else
        puts "WARN: The env var GITLAB_TOKEN is not configured. Will not post MR comment"
        false
      end
    end
  end
end
