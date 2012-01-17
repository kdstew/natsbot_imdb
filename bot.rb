require 'rubygems'
require 'nats/client'
require 'rest_client'
require 'json'
require 'yaml'

###
# Example output from imdbapi.com
####
#      {"Title"=>"Wag the Dog", "Year"=>"1997", "Rated"=>"R", "Released"=>"9 Jan 1998", "Genre"=>"Comedy, 
#        Drama", "Director"=>"Barry Levinson", "Writer"=>"Larry Beinhart, Hilary Henkin", 
#        "Actors"=>"Dustin Hoffman, Robert De Niro, Anne Heche, Denis Leary", 
#        "Plot"=>"Before elections, a spin-doctor and a Hollywood producer join efforts to fabricate a war in order to cover-up a presidential sex scandal.", 
#        "Poster"=>"http://ia.media-imdb.com/images/M/MV5BMTI4OTUzOTAwNl5BMl5BanBnXkFtZTcwOTc2NjEyMQ@@._V1_SX320.jpg",
#        "Runtime"=>"1 hr 37 mins", "Rating"=>"7.1", "Votes"=>"42164", "ID"=>"tt0120885", "Response"=>"True"}

["TERM", "INT"].each { |sig| trap(sig) { NATS.stop } }

def usage
  puts "Usage: auth_sub <user> <pass> <subject>"; exit
end

config = YAML.load(File.open('./config.yml'))

uri = config['uri']
subject = config['subject']

NATS.on_error { |err| puts "Server Error: #{err}"; exit! }

NATS.start(:uri => uri) do
  puts "Bot listening on [#{subject}]"
  NATS.subscribe(subject) do |msg, _, sub|

    if match = /@imdb\[(\d\d\d\d) (.*?)\]/.match(msg)
      year = match[1]
      title = match[2]

      # @imdb[year title]
      url = URI.encode("http://www.imdbapi.com/?t=#{title}&y=#{year}")
      response = RestClient.get url

      data = JSON.parse(response)
      message = "<img src=\"#{data['Poster']}\" /><br />"
      message += "#{data['Title']} was released in #{data['Year']} with a #{data['Rated']} rating.<br />"
      message += "Actors included #{data['Actors']}.<br />"
      message += "Plot: #{data['Plot']}<br />"

      NATS.publish(sub, message)
    end
  end
end
