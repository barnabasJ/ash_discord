defmodule AshDiscord.ConsumerExtension do
  @moduledoc """
  Spark DSL extension for AshDiscord consumers.
  
  This extension provides the `ash_discord_consumer` DSL block for configuring
  Discord consumer behavior and resource mappings.
  """
  
  use Spark.Dsl.Extension,
    sections: [AshDiscord.Dsl.Consumer.ash_discord_consumer()]
end