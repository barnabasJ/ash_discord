ExUnit.start()

# Start test applications
Application.ensure_all_started(:postgrex)
Application.ensure_all_started(:phoenix_pubsub)
Application.ensure_all_started(:ash_discord)

# Start test app
{:ok, _} = TestApp.Application.start(:normal, [])

# Configure Ecto sandbox
Ecto.Adapters.SQL.Sandbox.mode(TestApp.Repo, :manual)
