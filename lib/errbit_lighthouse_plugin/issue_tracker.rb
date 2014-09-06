require 'lighthouse'

module ErrbitLighthousePlugin
  class IssueTracker < ErrbitPlugin::IssueTracker

    LABEL = "lighthouseapp"

    FIELDS = [
      [:account, {
        :label       => "Subdomain",
        :placeholder => "subdomain from http://{{subdomain}}.lighthouseapp.com"
      }],
      [:api_token, {
        :label       => "API Token",
        :placeholder => "123456789abcdef123456789abcdef"
      }],
      [:project_id, {
        :label       => "Project ID",
        :placeholder => "123456"
      }]
    ]

    NOTE = ""

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    def self.fields
      FIELDS
    end

    def url
      sprintf(
        "http://%s.lighthouseapp.com/projects/%s",
        params[:subdomain],
        params[:project_id]
      )
    end

    def comments_allowed?
      false
    end

    # configured properly if all the fields are filled in
    def configured?
      non_empty_params = params.reject { |k,v| v.empty? }.keys.map(&:intern)
      required_fields  = FIELDS.map { |f| f[0].intern }

      (required_fields - non_empty_params).empty?
    end

    def errors
      errors = []
      if FIELDS.detect {|f| params[f[0]].blank? }
        errors << [:base, 'You must specify your Lighthouseapp Subdomain, API token and Project ID']
      end
      errors
    end

    def create_issue(problem, reported_by = nil)
      Lighthouse.account = params['account']
      Lighthouse.token   = params['api_token']
      # updating lighthouse account
      Lighthouse::Ticket.site
      Lighthouse::Ticket.format = :xml
      ticket = Lighthouse::Ticket.new(:project_id => params['project_id'])
      ticket.title = "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"

      ticket.body = self.class.body_template.result(binding)

      ticket.tags << "errbit"
      ticket.save!
      problem.update_attributes(
        :issue_link => ticket_link(ticket),
        :issue_type => self.class.label
      )
    end

    def ticket_link(ticket)
      Lighthouse::Ticket.site.to_s
        .sub(/#{Lighthouse::Ticket.site.path}$/, '') <<
      Lighthouse::Ticket.element_path(
        ticket.id, :project_id => params['project_id'])
        .sub(/\.xml$/, '')
    end

    def self.body_template
      @body_template ||= ERB.new(File.read(
        File.join(
          ErrbitLighthousePlugin.root, 'views', 'lighthouseapp_body.txt.erb'
        )
      ))
    end
  end
end
