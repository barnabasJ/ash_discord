ExUnit.start()
# Start Mimic for test mocking
Application.ensure_all_started(:mimic)
Mimic.copy(Nostrum.Api.Interaction)
