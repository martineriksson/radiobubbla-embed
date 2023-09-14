# frozen_string_literal: true

# name: radiobubbla-embed
# about: TODO
# version: 0.0.1
# authors: bubb.la
# url: https://radio.bubb.la
# required_version: 2.7.0

require 'net/http'
require 'uri'

enabled_site_setting :radiobubbla_embed_enabled

module ::RadioBubblaEmbedOnebox
  PLUGIN_NAME = "radiobubbla-embed"
end

after_initialize do
  module ::Onebox
    module Engine
      class RadioBubblaEmbedOnebox
        include Engine
        include StandardEmbed

        matches_regexp(/^https?:\/\/(rails\.)?radio\.bubb\.la\/.+/)

        def to_html
          uri = URI.parse(@url)

          segments = uri.path.split('/').reject(&:empty?)
          time = segments.length == 3 ? segments[-1] : nil
          id = segments.length == 3 ? segments[-2] : segments[-1]
          type = segments.length == 3 ? segments[-3] : segments[-2]

          secure_token = generate_secure_token(id, type)

          fetched_json = fetch_html(id, type, secure_token)
          fetched_data = ::JSON.parse(fetched_json)
          fetched_data["html"]
        end

        private

        def generate_secure_token(id, type)
          secret_key = ENV['RADIOBUBBLA_EMBED_SECRET_KEY']
          data = "#{id}#{type}"
          OpenSSL::HMAC.hexdigest('SHA256', secret_key, data)
        end

        def fetch_html(id, type, token)
          original_uri = URI.parse(@url)
          domain = "#{original_uri.scheme}://#{original_uri.host}"
          uri = URI.parse("#{domain}/oembed/#{type}/#{id}?token=#{token}")
          res = Net::HTTP.get_response(uri)
          res.body if res.is_a?(Net::HTTPSuccess)
        end
      end
    end
  end
end
