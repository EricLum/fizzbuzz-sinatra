require 'sinatra'
require 'mongoid'
require 'sinatra/namespace'

#Load MongoDB
Mongoid.load! "mongoid.config"

#Models
class Fizzbuzz
  include Mongoid::Document

  field :word, type: String
  field :max_length, type: Integer
  field :numbers, type: Array
  field :status, type: String

  validates :word, presence: true
  validates :max_length, presence:true

  index ({word: 'text'})
end

#Serializers for clean data.
class FizzbuzzSerializer

  #Create a fizzbuzz
  def initialize(fizzbuzz)
    @fizzbuzz = fizzbuzz
  end

  def as_json(*)
    data = {
      id: @fizzbuzz.id.to_s,
      word: @fizzbuzz.word,
      max_length: @fizzbuzz.max_length,
      numbers: @fizzbuzz.numbers,
      status: @fizzbuzz.status
    }
    data[:errors] = @fizzbuzz.errors if @fizzbuzz.errors.any?
    data
  end
end

#Endpoints
get '/' do
  'Welcome to Fizzbuzz!'
end

namespace '/api/v1' do

 #!Return responses as JSON.
  before do
    content_type 'application/json'
  end

  #!Helpers
helpers do
  def base_url
    @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
  end

  def json_params
    begin
      JSON.parse(request.body.read)
    rescue
      halt 400, { message:'Invalid JSON' }.to_json
    end
  end

end

#!Get index
  get '/fizzbuzz' do
  fizzbuzz = Fizzbuzz.all
    [:word, :max_length].each do |filter|
      fizzbuzz = books.send(filter, params[filter]) if params[filter]
  end
  # We just change this from books.to_json to the following
    fizzbuzz.map { |fizzbuzz| FizzbuzzSerializer.new(fizzbuzz) }.to_json
  end

  #! Get Endpoint
  get '/fizzbuzz/:id' do |id|
    fizzbuzz = Fizzbuzz.where(id: id).first
    halt(404, {message: 'Fizzbuzz Not Found'}.to_json) unless fizzbuzz
    FizzbuzzSerializer.new(fizzbuzz).to_json
  end

  #!Posting Endpoint
  post '/fizzbuzz' do
  fizzbuzz = Fizzbuzz.new(json_params)

#Create response based on word -- This is the main program.
  #Set return information.
  numbers = []
  status = ''

  if fizzbuzz.max_length <0
    status = 'Input must be an integer greater than zero.'
  else
    status = 'OK'
    case fizzbuzz.word
    when 'fizz'
      (1..fizzbuzz.max_length).each do |n|
        if (n%3 == 0)
          numbers << n
        end
      end
    when 'buzz'
      (1..fizzbuzz.max_length).each do |n|
        if (n%5 == 0)
          numbers << n
        end
      end
    when 'fizzbuzz'
      (1..fizzbuzz.max_length).each do |n|
      if ((n % 3 == 0) && (n % 5 == 0))
          numbers << n
        end
      end
    else
    status = 'Word is invalid. Must pass in fizz, buzz or fizzbuzz'
    end
  end

  fizzbuzz.status = status
  fizzbuzz.numbers = numbers

  if fizzbuzz.save
    response.headers['Location'] = "#{base_url}/api/v1/fizzbuzz/#{fizzbuzz.id}"
    status 201
  else
    status 422
    body FizzbuzzSerializer.new(fizzbuzz).to_json
  end

  end

end
