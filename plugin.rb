# frozen_string_literal: true

# name: radiobubbla-embed
# about: TODO
# version: 0.0.1
# authors: bubb.la
# url: https://radio.bubb.la
# required_version: 2.7.0

require 'net/http'
require 'uri'

#load File.expand_path('config/settings.yml', __dir__)

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
          params = CGI.parse(uri.query)
          id = params['id'].first
          type = params['type'].first
          secure_token = generate_secure_token(id, type)
          fetch_html(id, type, secure_token)
        end

        private

        def generate_secure_token(id, type)
          secret_key = ENV['RADIOBUBBLA_EMBED_SECRET_KEY']
          data = "#{id}#{type}"
          OpenSSL::HMAC.hexdigest('SHA256', secret_key, data)
        end

        def fetch_html(id, type, token)
          uri = URI.parse("https://radio.bubb.la/oembed/#{type}/#{id}?token=#{token}")
          res = Net::HTTP.get_response(uri)
          res.body if res.is_a?(Net::HTTPSuccess)
        end
      end
    end
  end
end

