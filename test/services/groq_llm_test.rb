require "test_helper"

class GroqLlmTest < ActiveSupport::TestCase
  Response = Struct.new(:code, :body)

  # Stands in for the HTTP connection and remembers what was sent.
  class FakeHttp
    attr_reader :requests

    def initialize(response)
      @response = response
      @requests = []
    end

    def request(request)
      @requests << request
      @response.respond_to?(:call) ? @response.call : @response
    end
  end

  setup do
    @board = create_agent_board
    @worker = @board.members.worker.first
    @mentor = @board.members.mentor.first
    @mentor.update!(model: "openai/gpt-oss-120b")
    @worker.update!(model: "openai/gpt-oss-20b")
    @card = create_agent_card(@board)
    @llm = GroqLlm.new(api_key: "test-key", retry_delay: 0)
  end

  def reply(content, finish_reason: "stop")
    Response.new("200", JSON.generate(choices: [ { message: { content: content }, finish_reason: finish_reason } ]))
  end

  # Runs the block with Net::HTTP.start replaced; returns [http, start_arguments].
  def with_http(response)
    http = FakeHttp.new(response)
    started = []
    starter = lambda do |*args, **options, &block|
      started << [ args, options ]
      block.call(http)
    end
    stub_class_method(Net::HTTP, :start, starter) { yield }
    [ http, started.first ]
  end

  test "write asks the worker's model for plain text, with low reasoning effort" do
    http, started = with_http(reply("  Ürün metni  ")) do
      assert_equal "Ürün metni", @llm.write(card: @card, worker: @worker, prompt: "Görev: x")
    end

    request = http.requests.sole
    body = JSON.parse(request.body)
    assert_equal "openai/gpt-oss-20b", body["model"]
    assert_equal 800, body["max_tokens"]
    assert_equal "Görev: x", body["messages"].last["content"]
    assert_not body.key?("response_format")
    assert_equal "low", body["reasoning_effort"]
    assert_equal "Bearer test-key", request["Authorization"]
    assert_equal "/openai/v1/chat/completions", request.path

    assert_equal [ "api.groq.com", 443 ], started.first
    assert_equal({ use_ssl: true, open_timeout: 5, read_timeout: 20 }, started.last)
  end

  test "review asks the mentor's model for strict json_schema output" do
    verdict = { verdict: "pass", criteria: [ { item_id: 1, met: true, reason: "ok" } ], feedback: "", lesson: "" }
    http, = with_http(reply(JSON.generate(verdict))) do
      result = @llm.review(card: @card, mentor: @mentor, prompt: "İncele")
      assert_equal "pass", result[:verdict]
      assert_equal 1, result[:criteria].first[:item_id]
    end

    body = JSON.parse(http.requests.sole.body)
    assert_equal "openai/gpt-oss-120b", body["model"]
    assert_equal 2000, body["max_tokens"]
    assert_equal "medium", body["reasoning_effort"]
    assert_includes body["messages"].first["content"], "met=false"

    format = body["response_format"]
    assert_equal "json_schema", format["type"]
    assert_equal true, format["json_schema"]["strict"]

    schema = format["json_schema"]["schema"]
    assert_equal %w[ verdict criteria feedback lesson ], schema["required"]
    assert_equal %w[ pass revise escalate ], schema["properties"]["verdict"]["enum"]
    item = schema["properties"]["criteria"]["items"]
    assert_equal %w[ item_id met reason ], item["required"]
    [ schema, item ].each { |object| assert_equal false, object["additionalProperties"] }
  end

  test "reasoning_effort is only sent to gpt-oss models, for write and review" do
    @mentor.update!(model: "llama-3.3-70b-versatile")
    @worker.update!(model: "llama-3.3-70b-versatile")
    review, = with_http(reply("{}")) { @llm.review(card: @card, mentor: @mentor, prompt: "x") }
    write, = with_http(reply("metin")) { @llm.write(card: @card, worker: @worker, prompt: "x") }

    [ review, write ].each { |http| assert_not JSON.parse(http.requests.sole.body).key?("reasoning_effort") }
  end

  test "an empty write answer (a reasoning model out of tokens) raises LlmError" do
    [ reply(""), reply(nil, finish_reason: "length") ].each do |response|
      with_http(response) do
        error = assert_raises(LlmError) { @llm.write(card: @card, worker: @worker, prompt: "x") }
        assert_match(/boş/, error.message)
      end
    end
  end

  test "HTTP errors, truncated and broken answers raise LlmError" do
    {
      Response.new("429", "rate limited") => /429/,
      Response.new("503", "<html>down</html>") => /503/,
      Response.new("200", "not json") => /JSON/,
      Response.new("200", "{}") => /choices/,
      reply("{\"verdict\":\"pa", finish_reason: "length") => /kesildi/,
      reply("not json at all") => /JSON/
    }.each do |response, message|
      error = nil
      with_http(response) do
        error = assert_raises(LlmError) { @llm.review(card: @card, mentor: @mentor, prompt: "x") }
      end
      assert_match message, error.message
    end
  end

  test "timeouts and connection errors raise LlmError without leaking the key" do
    [ Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, SocketError, Socket::ResolutionError ].each do |failure|
      error = nil
      stub_class_method(Net::HTTP, :start, ->(*, **, &) { raise failure }) do
        error = assert_raises(LlmError) { @llm.write(card: @card, worker: @worker, prompt: "x") }
      end
      assert_no_match(/test-key/, error.message)
    end
  end

  # Net::HTTP.start fails with each of the given errors in turn, then answers with the response.
  def with_failing_network(errors, response)
    calls = 0
    http = FakeHttp.new(response)
    starter = lambda do |*, **, &block|
      calls += 1
      raise errors[calls - 1] if calls <= errors.size

      block.call(http)
    end
    stub_class_method(Net::HTTP, :start, starter) { yield }
    calls
  end

  test "a network error is retried exactly once" do
    calls = with_failing_network([ Socket::ResolutionError ], reply("Metin")) do
      assert_equal "Metin", @llm.write(card: @card, worker: @worker, prompt: "x")
    end

    assert_equal 2, calls
  end

  test "two network errors in a row give up after exactly two tries" do
    calls = with_failing_network([ Net::ReadTimeout, Net::ReadTimeout, Net::ReadTimeout ], reply("Metin")) do
      error = assert_raises(LlmError) { @llm.write(card: @card, worker: @worker, prompt: "x") }
      assert_match(/2 deneme/, error.message)
    end

    assert_equal 2, calls
  end

  test "the retry waits for the retry delay" do
    llm = GroqLlm.new(api_key: "test-key", retry_delay: 0.25)
    slept = []

    llm.define_singleton_method(:sleep) { |seconds| slept << seconds }
    with_failing_network([ SocketError ], reply("Metin")) { llm.write(card: @card, worker: @worker, prompt: "x") }

    assert_equal [ 0.25 ], slept
  end

  test "an HTTP error status is never retried" do
    [ "400", "401", "404", "429", "500" ].each do |code|
      http, = with_http(Response.new(code, "no")) do
        assert_raises(LlmError) { @llm.write(card: @card, worker: @worker, prompt: "x") }
      end
      assert_equal 1, http.requests.size, "HTTP #{code} was retried"
    end
  end

  test "an HTTP error message is short" do
    with_http(Response.new("500", "x" * 5000)) do
      error = assert_raises(LlmError) { @llm.write(card: @card, worker: @worker, prompt: "x") }
      assert_operator error.message.length, :<, 260
    end
  end

  test "needs a key" do
    assert_raises(ArgumentError) { GroqLlm.new(api_key: "") }
    assert_raises(ArgumentError) { GroqLlm.new(api_key: nil) }
  end

  test "is not a simulation" do
    assert_not @llm.simulated?
  end
end
