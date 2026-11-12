
require "net/http"
require "json"

class WhatsappSender
  def self.send_test
    version = ENV.fetch("WHATSAPP_API_VERSION")
    phone_id = ENV.fetch("WHATSAPP_PHONE_NUMBER_ID")

    uri = URI("https://graph.facebook.com/#{version}/#{phone_id}/messages")

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{ENV.fetch('WHATSAPP_ACCESS_TOKEN')}"
    request["Content-Type"] = "application/json"

    request.body = {
      messaging_product: "whatsapp",
      to: ENV.fetch("WHATSAPP_TEST_RECIPIENT"),
      type: "text",
      text: {
        body: "Bem-vindo ao Hotel Moreno!\n\n" \
              "Código do quarto: 123456\n" \
              "Senha do Wi-Fi: Moreno2026"
      }
    }.to_json

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true,
      open_timeout: 5,
      read_timeout: 15
    ) { |http| http.request(request) }

    {
      success: response.is_a?(Net::HTTPSuccess),
      status: response.code.to_i,
      body: JSON.parse(response.body)
    }
  end
end
