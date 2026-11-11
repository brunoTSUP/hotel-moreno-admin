
require "openssl"
require "json"

module Webhooks
  class WhatsappController < ActionController::Base
    skip_forgery_protection only: :receive

    def verify
      token = ENV["WHATSAPP_VERIFY_TOKEN"].to_s
      received_token = params["hub.verify_token"].to_s

      valid_token =
        token.present? &&
        ActiveSupport::SecurityUtils.secure_compare(
          token,
          received_token
        )

      if params["hub.mode"] == "subscribe" && valid_token
        render plain: params["hub.challenge"].to_s,
               content_type: "text/plain"
      else
        head :forbidden
      end
    end

    def receive
      raw_body = request.raw_post
      signature = request.headers["X-Hub-Signature-256"].to_s
      app_secret = ENV["WHATSAPP_APP_SECRET"].to_s

      return head :service_unavailable if app_secret.blank?

      expected_signature = "sha256=" + OpenSSL::HMAC.hexdigest(
        "SHA256",
        app_secret,
        raw_body
      )

      unless ActiveSupport::SecurityUtils.secure_compare(
        expected_signature,
        signature
      )
        return head :unauthorized
      end

      payload = JSON.parse(raw_body)

      Rails.logger.info(
        "[WhatsApp Webhook] Evento recebido: " \
        "object=#{payload['object']} " \
        "entries=#{payload.fetch('entry', []).size}"
      )

      payload.fetch("entry", []).each do |entry|
        entry.fetch("changes", []).each do |change|
          next unless change["field"] == "messages"

          value = change.fetch("value", {})

          value.fetch("statuses", []).each do |status|
            Rails.logger.info(
              "[WhatsApp] Status: #{status['status']} " \
              "message_id=#{status['id']}"
            )
          end

          value.fetch("messages", []).each do |message|
            Rails.logger.info(
              "[WhatsApp] Mensagem recebida: " \
              "message_id=#{message['id']} " \
              "type=#{message['type']}"
            )
          end
        end
      end

      head :ok
    rescue JSON::ParserError
      head :bad_request
    end
  end
end
