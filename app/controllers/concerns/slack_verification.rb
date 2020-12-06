module SlackVerification
  extend ActiveSupport::Concern

  included do
    before_action :verify_signed_secret
  end

  def verify_signed_secret
    render nothing: true, status: :unauthorized unless SlackMsgr::Authenticate.signing_secret?(request)
  end
end
