require 'bundler/setup'
require 'json'
require 'net/http'

Bundler.require

if File.exist?("env.rb")
  load "./env.rb"
end

ENV["AUTHY_API_URL"] ||= "https://api.authy.com"

DOCUMENTATION = %@Proceso de registro:

    POST /registro
    parametros:
      authy_id <usuario authy id>

Esto devolverá un token de registro que debe pasar al SDK para completar el proceso de registro.
@

helpers do
  def respond_with(status:, body: {})
    halt status, {'Content-Type' => 'application/json'}, body.to_json
  end

  def build_url(path)
    "#{ENV["AUTHY_API_URL"]}#{path}"
  end

  def build_params_for_authy(authy_id)
    {
      api_key: ENV["AUTHY_API_KEY"],
      authy_id: authy_id
    }
  end
end

get "/" do
  content_type :text

  DOCUMENTATION
end

post "/registro" do
  param :authy_id, Integer, required: true

  params_for_authy = build_params_for_authy(params[:authy_id])

  response = Net::HTTP.post_form(URI.parse(build_url("/protected/json/sdk/registrations")), params_for_authy)
  response_code = response.code.to_i

  parsed_response = JSON.parse(response.body)

  if response_code == 200
    respond_with status: response_code, body: {token: parsed_response["registration_token"] }

  else
    respond_with status: response_code, body: parsed_response

  end
end

post "/verify/token" do
  param :phone_number, String, required: true

  payload = {
    app_id: ENV["APP_ID"],
    phone_number: params[:phone_number],
    iat: Time.now.to_i
  }

  jwt_token = JWT.encode(payload, ENV["AUTHY_API_KEY"], "HS256")

  respond_with status: 200, body: {jwt_token: jwt_token}
end
