defmodule TestApp.Discord.Event do
  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    domain: TestApp.Discord

  ash_discord do
    events do
      on(:RESUMED, :resume)
    end
  end

  actions do
    action :resume do
      run(fn _record, _context ->
        require Logger
        Logger.error("Resumed action invoked")
        :ok
      end)
    end
  end
end
