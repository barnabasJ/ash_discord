defmodule TestApp.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use TestApp.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      use Mimic
      import Mimic
    end
  end

  setup _ do
    # Clean up ETS tables between tests
    on_exit(fn ->
      # Clear all data from test resources
      Application.spec(:ash_discord, :modules)
      |> Enum.filter(&match?("Elixir.TestApp.Discord" <> _, Atom.to_string(&1)))
      |> Enum.filter(&Ash.Resource.Info.resource?/1)
      |> Enum.each(&Ash.DataLayer.Ets.stop/1)
    end)

    :ok
  end
end
