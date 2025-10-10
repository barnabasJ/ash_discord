defmodule TestApp.Discord.Event do
  use Ash.Resource,
    extensions: [AshDiscord.Resource],
    authorizers: [Ash.Policy.Authorizer],
    domain: TestApp.Discord

  ash_discord do
    events do
      on(:READY, :ready)
      on(:RESUMED, :resume)
    end
  end

  policies do
    bypass AshDiscord.Checks.AshDiscordInteraction do
      authorize_if(always())
    end
  end

  actions do
    action :ready do
      argument(:data, AshDiscord.Consumer.Payloads.ReadyEvent, allow_nil?: false)

      run(fn input, _context ->
        require Logger
        Logger.error("Ready action invoked: #{inspect(input.arguments.data)}")
        :ok
      end)
    end

    action :resume do
      run(fn _input, _context ->
        require Logger
        Logger.error("Resumed action invoked")
        :ok
      end)
    end
  end
end
