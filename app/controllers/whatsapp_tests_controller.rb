class WhatsappTestsController < ApplicationController
  def index
  end

  def create
    result = WhatsappSender.send_test

    if result[:success]
      redirect_back fallback_location: root_path,
        notice: "Mensagem aceita pela API do WhatsApp!"
    else
      Rails.logger.warn(
        "WhatsApp test failed: #{result[:body]}"
      )

      redirect_back fallback_location: root_path,
        alert: "Erro no WhatsApp: HTTP #{result[:status]}"
    end
  rescue StandardError => e
    Rails.logger.error(
      "WhatsApp test error: #{e.class}: #{e.message}"
    )

    redirect_back fallback_location: root_path,
      alert: "Falha ao executar o teste."
  end
end
