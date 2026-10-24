module BoardsHelper
  NAMED_LIST_TONES = {
    "To Do" => "bg-violet-100/70 ring-violet-200",
    "Doing" => "bg-amber-100/70 ring-amber-200",
    List::DONE_NAME => "bg-emerald-100/70 ring-emerald-200",
    List::OVERDUE_NAME => "bg-linear-to-b from-rose-100 to-orange-100 ring-2 ring-rose-400 animate-sla-pulse",
    # Agent boards: the hand-over list looks like Gecikenler.
    List::POOL_NAME => "bg-sky-100/70 ring-sky-200",
    List::REVIEW_NAME => "bg-violet-100/70 ring-violet-200",
    List::REWORK_NAME => "bg-amber-100/70 ring-amber-200",
    List::HUMAN_NAME => "bg-linear-to-b from-rose-100 to-orange-100 ring-2 ring-rose-400 animate-sla-pulse"
  }.freeze

  LIST_COLOR_TONES = {
    "sky" => "bg-sky-100/70 ring-sky-200",
    "rose" => "bg-rose-100/70 ring-rose-200",
    "teal" => "bg-teal-100/70 ring-teal-200",
    "lime" => "bg-lime-100/70 ring-lime-200",
    "indigo" => "bg-indigo-100/70 ring-indigo-200",
    "fuchsia" => "bg-fuchsia-100/70 ring-fuchsia-200",
    "cyan" => "bg-cyan-100/70 ring-cyan-200",
    "pink" => "bg-pink-100/70 ring-pink-200"
  }.freeze

  LABEL_TONES = {
    "red" => "bg-rose-500",
    "purple" => "bg-violet-500",
    "blue" => "bg-sky-500",
    "orange" => "bg-orange-500",
    "green" => "bg-emerald-500",
    "yellow" => "bg-amber-400"
  }.freeze

  MEMBER_TONES = {
    "pink" => "bg-pink-200 text-pink-800",
    "sky" => "bg-sky-200 text-sky-800",
    "emerald" => "bg-emerald-200 text-emerald-800",
    "amber" => "bg-amber-200 text-amber-800",
    "violet" => "bg-violet-200 text-violet-800",
    "teal" => "bg-teal-200 text-teal-800"
  }.freeze

  # Time travel for live demos; never on a public production site unless DEMO_MODE is set.
  def demo_time_travel?
    Rails.env.development? || ENV["DEMO_MODE"].present?
  end

  def list_tone(list)
    NAMED_LIST_TONES[list.name] || LIST_COLOR_TONES.fetch(list.color.to_s, LIST_COLOR_TONES["sky"])
  end

  def label_tone(label)
    LABEL_TONES.fetch(label.color, "bg-slate-300")
  end

  def member_avatar(member, size: "size-7")
    tag.span member.initials, title: member.name,
      class: "#{size} #{MEMBER_TONES.fetch(member.color, MEMBER_TONES["sky"])} inline-flex shrink-0 items-center justify-center rounded-full text-[11px] font-bold ring-2 ring-white"
  end
end
