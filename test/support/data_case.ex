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
  end

  setup _ do
    # Clean up ETS tables between tests
    on_exit(fn ->
      # Clear all data from test resources
      TestApp.Discord.Message
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      TestApp.Discord.Guild
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)

      TestApp.Discord.User
      |> Ash.read!()
      |> Enum.each(&Ash.destroy!/1)
    end)

    :ok
  end
end
