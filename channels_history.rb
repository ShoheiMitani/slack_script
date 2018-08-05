require 'faraday'
require 'json'
require 'date'

# You can get slack messages using search word in the particular channel.
# How to use
# bundle exec ruby channels_history.rb #{slack token} #{slack channel id} #{target year} #{target month} #{search word}

class SlackClient
  SLACK_URL = 'https://slack.com'

  def initialize(token:, channel_id:)
    @token = token
    @channel_id = channel_id
    @conn = Faraday.new(url: SLACK_URL) do |builder|
      builder.request  :url_encoded
      # builder.response :logger
      builder.adapter  :net_http
    end
  end

  def channels_history(start_at:, end_at:)
    response = @conn.get do |req|
      req.url '/api/channels.history'
      req.params[:token] = @token
      req.params[:channel] = @channel_id
      req.params[:count] = 1000 # 最大100件ぽい
      req.params[:oldest] = start_at.to_i
      req.params[:latest] = end_at.to_i
    end

    body = JSON.parse(response.body)
    body['messages']
  end
end

token = ARGV[0]
channel_id = ARGV[1]
year = ARGV[2].to_i
month = ARGV[3].to_i
word = ARGV[4]

client = SlackClient.new(
    token: token,
    channel_id: channel_id,
)

days = (Date.new(year, month, -1) - Date.new(year, month)).numerator + 1

days.times do |day|
  messages = client.channels_history(
      start_at: Time.local(year, month, day + 1, 0, 0, 0),
      end_at: Time.local(year, month, day + 1, 23, 59, 59),
  )

  messages.each do |message|
    text = message['text']
    p text if /^.*#{word}.*$/ === text
  end
end
