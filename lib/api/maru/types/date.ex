defmodule Maru.Types.Date do
  use Maru.Type

  def parse(date) do
    [_, _, _] = Regex.run(
      ~r/(\d{4})-(0?\d|1[012])-([012]?\d|3[01])/, date, capture: :all_but_first
    )

    date
  end
end
