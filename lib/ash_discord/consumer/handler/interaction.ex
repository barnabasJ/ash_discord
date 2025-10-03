defmodule AshDiscord.Consumer.Handler.Interaction do
  require Logger

  @spec create(
          consumer :: module(),
          interaction :: Nostrum.Struct.Interaction.t(),
          ws_state :: Nostrum.Struct.WSState.t()
        ) :: any()
  def create(_consumer, interaction, _ws_state) do
    Logger.debug("Processing Discord interaction: #{interaction.id}")
    # Note: Library users can implement their own interaction processing here
    :ok
  end
end
