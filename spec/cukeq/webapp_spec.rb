require "#{File.dirname(__FILE__)}/../spec_helper"

describe CukeQ::WebApp do
  include Rack::Test::Methods

  def app
    CukeQ::WebApp.new(URI.parse("http://localhost:9292"))
  end

  it "errors if the request is not a POST" do
    get "/"

    last_response.should_not be_ok
    last_response.headers['Allow'].should == 'POST'
  end

  it "errors if the POST body is not valid JSON" do
    post "/", 'not json'

    last_response.should_not be_ok
    last_response.headers['Content-Type'].should == 'application/json'
  end

  it "accepts valid JSON" do
    post "/", '{"some":"data"}'

    last_response.status.should == 202
    last_response.body.should == "ok"
  end

end