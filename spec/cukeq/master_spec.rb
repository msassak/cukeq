require "#{File.dirname(__FILE__)}/../spec_helper"

describe CukeQ::Master do
  def mock_master
    CukeQ::Master.new(
      mock("CukeQ::Broker",   :null_object => true),
      mock("CukeQ::WebApp",   :null_object => true),
      mock("CukeQ::Scm",      :null_object => true),
      mock("CukeQ::Reporter", :null_object => true),
      mock("CukeQ::Exploder", :null_object => true)
    )
  end

  def running_master
    master = mock_master
    master.broker.stub!(:start).and_yield
    master.start

    master
  end

  describe ".configured_instance" do
    it "sets up defaults if --broker is not given" do
      master = CukeQ::Master.configured_instance(
        %w[-s git://example.com -r http://cukereports.com]
      )

      master.broker.host.should  == 'localhost'
      master.broker.port.should  == 5672
      master.broker.user.should  == 'cukeq-master'
      master.broker.pass.should  == 'cukeq123'
      master.broker.vhost.should == '/cukeq'
    end

    it "adds defaults if the --broker argument is incomplete" do
      master = CukeQ::Master.configured_instance(
        %w[--broker amqp://otherhost:9000 -s git://example.com -r http://cukereports.com]
      )

      master.broker.host.should  == 'otherhost'
      master.broker.port.should  == 9000
      master.broker.user.should  == 'cukeq-master'
      master.broker.pass.should  == 'cukeq123'
      master.broker.vhost.should == '/cukeq'
    end

    it "sets up defaults if --webapp is not given" do
      master = CukeQ::Master.configured_instance(
        %w[-s git://example.com -r http://cukereports.com]
      )

      master.webapp.uri.host.should == 'localhost'
      master.webapp.uri.port.should == 9292
    end
  end

  describe ".execute" do
    it "starts the configured instance" do
      args   = %w[some args]
      master = mock_master

      CukeQ::Master.should_receive(:configured_instance).with(args).and_return(master)
      master.should_receive(:start)

      CukeQ::Master.execute(args)
    end
  end

  describe "#start" do
    it "subscribes to the results queue and runs the webapp" do
      master = CukeQ::Master.new(mock("CukeQ::Broker"), mock("CukeQ::WebApp"), nil, nil, nil)
      master.broker.should_receive(:start).and_yield
      master.should_receive(:subscribe)
      master.webapp.should_receive(:run)

      master.start
    end
  end

  describe "#run" do
    it "sends the payload to the exploder" do
      features = ["some.feature:10", "another.feature:12"]
      master   = running_master

      master.exploder.should_receive(:explode).with(features).and_return([])
      master.run(features)
    end

    it "publishes the exploded scenarios on the jobs queue" do
      jobs   = %w[job1 job2 job3 job4]
      master = running_master

      master.exploder.should_receive(:explode).and_return(jobs)
      master.broker.should_receive(:publish).exactly(4).times # TODO: how to specify the args?

      master.run(nil)
    end
  end

  describe "#result" do
    it "sends the result to the reporter" do
      result = {:some => 'data'}
      master = running_master
      master.reporter.should_receive(:report).with(result)

      master.result(result)
    end
  end

  describe "#subscribe" do
    it "should subscribe to the results queue and process the result" do
      master = running_master
      result = '{"some": "result"}'

      master.broker.should_receive(:subscribe).with(:results).and_yield(result)
      master.should_receive(:result).with("some" => "result")

      master.subscribe
    end
  end

end