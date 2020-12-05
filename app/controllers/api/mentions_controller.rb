module Api
  class MentionsController < ApplicationController
    before_action :return_challenge, if: :challenge_param_present?

    def create
      app_mention_service = AppMentionService.new(event_params, "ho ho ho")
      app_mention_service.handle_message
      ok_response = app_mention_service.respond

      render json: { ok: ok_response }
    end

    private

    def event_params
      params.require(:event).permit(:user, :ts, :text, :channel)
    end

    def challenge_param_present?
      params[:challenge].present?
    end

    def return_challenge
      render json: { challenge: params[:challenge] }
    end
  end
end
