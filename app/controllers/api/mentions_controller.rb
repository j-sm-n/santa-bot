module Api
  class MentionsController < ApplicationController
    before_action :return_challenge, if: :challenge_param_present?
    before_action :return_noop_success, if: :message_from_self?

    def create
      user = User.find_or_create_by(slack_id: event_params[:user])
      app_mention_service = AppMentionService.new(event_params, user)

      update_user_dm_channel(user) if app_mention_service.message_sent_in_im? && user.dm_channel_id.blank?

      app_mention_service.handle_message
      ok_response = app_mention_service.respond

      render json: { ok: ok_response }
    end

    private

    def event_params
      params.require(:event).permit(:user, :ts, :text, :channel, :channel_type)
    end

    def challenge_param_present?
      params[:challenge].present?
    end

    def message_from_self?
      params[:event][:bot_id].present?
    end

    def return_challenge
      render json: { challenge: params[:challenge] }
    end

    def return_noop_success
      render json: { ok: true }
    end

    def update_user_dm_channel(user)
      user.update(dm_channel_id: event_params[:channel])
    end
  end
end
