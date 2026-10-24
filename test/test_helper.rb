ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # The threshold stays high: threaded workers hang on the Windows dev machine (they also hung on the
    # 34 pre-agent tests when forced), and the suite is too small to need them.
    parallelize(workers: :number_of_processors, with: :threads, threshold: 500)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Replaces a class method for the length of the block (minitest/mock is a separate gem in Minitest 6).
    def stub_class_method(klass, name, replacement)
      original = klass.method(name)
      klass.define_singleton_method(name) { |*args, **options, &block| replacement.call(*args, **options, &block) }
      yield
    ensure
      klass.define_singleton_method(name, original)
    end

    # An agent board with its fixed lists, a mentor and the given number of workers.
    def create_agent_board(workers: 1)
      board = Board.create!(name: "Ajan panosu", kind: :agent)
      board.ensure_agent_lists!
      workers.times { |i| board.members.create!(name: "Işçi #{i + 1}", kind: :agent, role: :worker, model: "worker-model") }
      board.members.create!(name: "Mentor", kind: :agent, role: :mentor, model: "mentor-model")
      board
    end

    # A card in the pool whose acceptance criteria are its checklist items.
    def create_agent_card(board, title: "Kart", criteria: [ "Kısa olsun", "Emoji olmasın" ])
      pool = board.agent_list(:open)
      card = pool.cards.create!(title: title, description: "Açıklama", agent_state: :open,
                                position: pool.cards.maximum(:position).to_i + 1)
      criteria.each { |content| card.checklist_items.create!(content: content) }
      card
    end
  end
end
