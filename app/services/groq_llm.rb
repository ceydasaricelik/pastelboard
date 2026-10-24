require "net/http"
require "json"

# The real model, through Groq's OpenAI-compatible API. Same interface as FakeLlm.
# The key is only ever read from ENV["GROQ_API_KEY"]; it never goes into a message, event or log.
class GroqLlm
  ENDPOINT = URI("https://api.groq.com/openai/v1/chat/completions")
  OPEN_TIMEOUT = 5
  READ_TIMEOUT = 20
  # gpt-oss models spend part of these on reasoning before they answer.
  WRITE_MAX_TOKENS = 800
  REVIEW_MAX_TOKENS = 2000
  WRITE_REASONING = "low"
  REVIEW_REASONING = "medium"
  RETRY_DELAY = 1
  NETWORK_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, Net::WriteTimeout, SocketError, EOFError,
    Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EHOSTUNREACH, Errno::ENETUNREACH, OpenSSL::SSL::SSLError
  ].freeze

  WRITER_ROLE = "Sen kısa metinler yazan bir yazarsın. Yalnızca teslim edilecek metni yaz, açıklama ekleme. " \
                "Görev için gereken bilgi kartta yoksa uydurma."
  MENTOR_ROLE = "Sen çok titiz bir mentorsun. Teslimi kabul kriterlerine göre incele ve yalnızca istenen JSON'u döndür. " \
                "Her kriteri harfiyen kontrol et; kelime ve madde sayılarını tek tek say. Emin değilsen met=false ver. " \
                "Kartta olmayan bir bilgi (ürün adı, özellik, fiyat vb.) çıktıda geçiyorsa bu uydurmadır: revise. " \
                "Görev karttaki bilgiyle yapılamıyorsa: escalate."

  REVIEW_SCHEMA = {
    type: "object",
    properties: {
      verdict: { type: "string", enum: %w[ pass revise escalate ] },
      criteria: {
        type: "array",
        items: {
          type: "object",
          properties: {
            item_id: { type: "integer" },
            met: { type: "boolean" },
            reason: { type: "string" }
          },
          required: %w[ item_id met reason ],
          additionalProperties: false
        }
      },
      feedback: { type: "string" },
      lesson: { type: "string" }
    },
    required: %w[ verdict criteria feedback lesson ],
    additionalProperties: false
  }.freeze

  # A network error is retried once, after retry_delay seconds.
  def initialize(api_key: ENV["GROQ_API_KEY"], retry_delay: RETRY_DELAY)
    raise ArgumentError, "GROQ_API_KEY is not set" if api_key.blank?

    @api_key = api_key
    @retry_delay = retry_delay
  end

  def simulated?
    false
  end

  def write(card:, worker:, prompt:)
    content, = complete(
      model: worker.model, max_tokens: WRITE_MAX_TOKENS,
      messages: [ { role: "system", content: WRITER_ROLE }, { role: "user", content: prompt } ],
      **reasoning(worker.model, WRITE_REASONING)
    )
    # A reasoning model that ran out of tokens answers with nothing.
    raise LlmError, "Groq boş cevap döndü" if content.to_s.strip.empty?

    content.to_s.strip
  end

  def review(card:, mentor:, prompt:)
    body = {
      model: mentor.model, max_tokens: REVIEW_MAX_TOKENS,
      messages: [ { role: "system", content: MENTOR_ROLE }, { role: "user", content: prompt } ],
      response_format: { type: "json_schema", json_schema: { name: "review", strict: true, schema: REVIEW_SCHEMA } },
      **reasoning(mentor.model, REVIEW_REASONING)
    }

    content, finish_reason = complete(**body)
    raise LlmError, "Groq cevabı max_tokens sınırında kesildi" if finish_reason == "length"

    JSON.parse(content.to_s, symbolize_names: true)
  rescue JSON::ParserError
    raise LlmError, "Groq cevabı JSON olarak ayrıştırılamadı"
  end

  private
    # Only the gpt-oss models take reasoning_effort.
    def reasoning(model, effort)
      model.to_s.start_with?("openai/gpt-oss") ? { reasoning_effort: effort } : {}
    end

    # Returns [content, finish_reason] of the first choice.
    def complete(**body)
      response = post(body)
      raise LlmError, "Groq HTTP #{response.code}: #{response.body.to_s.squish.truncate(200)}" unless response.code.to_s.start_with?("2")

      choice = JSON.parse(response.body).dig("choices", 0)
      raise LlmError, "Groq cevabında choices yok" unless choice

      [ choice.dig("message", "content"), choice["finish_reason"] ]
    rescue JSON::ParserError
      raise LlmError, "Groq cevabı JSON olarak ayrıştırılamadı"
    end

    # Network errors (DNS, connection, timeouts) get one more try; HTTP error statuses never do.
    def post(body)
      request = Net::HTTP::Post.new(ENDPOINT)
      request["Content-Type"] = "application/json"
      request["Authorization"] = "Bearer #{@api_key}"
      request.body = JSON.generate(body)

      tries = 0
      begin
        tries += 1
        Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
          http.request(request)
        end
      rescue *NETWORK_ERRORS => error
        if tries < 2
          sleep @retry_delay
          retry
        end
        raise LlmError, "Groq isteği başarısız (#{error.class}, #{tries} deneme)"
      end
    end
end
