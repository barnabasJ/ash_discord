defmodule AshDiscord.LogTracer do
  @moduledoc """
  A simple Ash tracer that logs all trace events for debugging.

  ## Usage

  Enable globally:

      config :ash, :tracer, AshDiscord.LogTracer

  Or per-action:

      YourResource
      |> Ash.Changeset.for_create(:create, %{}, tracer: AshDiscord.LogTracer)
      |> Ash.create!()

  Or in tests:

      TestApp.Discord.message_from_discord!(
        %{data: message},
        tracer: AshDiscord.LogTracer
      )
  """

  require Logger
  use Ash.Tracer

  @impl true
  def start_span(type, name) do
    Logger.debug([
      IO.ANSI.blue(),
      "[TRACE START] ",
      IO.ANSI.cyan(),
      inspect(type),
      IO.ANSI.reset(),
      " - ",
      name
    ])

    :ok
  end

  @impl true
  def stop_span do
    Logger.debug([IO.ANSI.green(), "[TRACE STOP]", IO.ANSI.reset()])
    :ok
  end

  @impl true
  def set_metadata(_type, metadata) do
    Logger.debug([
      IO.ANSI.yellow(),
      "[TRACE METADATA] ",
      IO.ANSI.reset(),
      inspect(metadata, pretty: true, limit: :infinity)
    ])

    :ok
  end

  @impl true
  def get_span_context do
    nil
  end

  @impl true
  def set_span_context(_context) do
    :ok
  end

  @impl true
  def set_error(error) do
    Logger.error([
      IO.ANSI.red(),
      "[TRACE ERROR] ",
      IO.ANSI.reset(),
      inspect(error, pretty: true)
    ])

    :ok
  end
end
