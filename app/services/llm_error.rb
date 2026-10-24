# Raised when the model could not give a usable answer: HTTP errors, timeouts, broken or invalid replies.
# The card stays where it is and the round goes on.
class LlmError < StandardError; end
