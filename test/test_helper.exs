ExUnit.start()
# Start Mimic for test mocking
Application.ensure_all_started(:mimic)

# Automatically copy all Nostrum API modules for mocking
Application.spec(:nostrum, :modules)
|> Enum.filter(&match?("Elixir.Mimic.Api" <> _, Atom.to_string(&1)))
|> Enum.each(&Mimic.copy/1)
