defmodule AshDiscord.Context do
  @moduledoc """
  Discord event context for passing through Ash operations.

  This context carries Discord-specific information like the consumer module,
  guild context, user information, and WebSocket state. It implements the
  `Ash.Scope.ToOpts` protocol to provide actor, tenant, and context information
  to Ash operations.
  """

  defstruct [
    :user,
    :user_id,
    :guild_id
  ]

  @type t :: %__MODULE__{
          user: Nostrum.Struct.User.t() | nil,
          user_id: Nostrum.Snowflake.t() | nil,
          guild_id: Nostrum.Snowflake.t() | nil
        }

  defimpl Ash.Scope.ToOpts do
    @doc "Extract the actor (user) from the context"
    def get_actor(%{user: user}) when not is_nil(user), do: {:ok, user}
    def get_actor(_), do: :error

    @doc "Extract the tenant (guild) from the context"
    def get_tenant(%{guild_id: guild_id}) when not is_nil(guild_id),
      do: {:ok, guild_id}

    def get_tenant(_), do: :error

    @doc "Extract shared context information"
    def get_context(_context) do
      :error
    end

    @doc "Tracers are typically configured elsewhere"
    def get_tracer(_), do: :error

    @doc "Authorization should be handled by policies, not scope"
    def get_authorize?(_), do: :error
  end

  @doc """
  Extracts context information from various Discord event payloads.
  Pattern matches on different event structures to extract user and guild info.
  """

  # Message events (MESSAGE_CREATE, MESSAGE_UPDATE) - has author field
  def from_payload(
        _consumer,
        %{author: %Nostrum.Struct.User{} = user, guild_id: guild_id},
        _ws_state
      ) do
    %__MODULE__{
      user: user,
      user_id: user.id,
      guild_id: guild_id
    }
  end

  # Interaction events (INTERACTION_CREATE) - has user field
  def from_payload(
        _consumer,
        %Nostrum.Struct.Interaction{user: user, guild_id: guild_id},
        _ws_state
      ) do
    %__MODULE__{
      user: user,
      user_id: user.id,
      guild_id: guild_id
    }
  end

  # Voice State events - has user_id but not full user struct
  def from_payload(
        _consumer,
        %Nostrum.Struct.Event.VoiceState{user_id: user_id, guild_id: guild_id},
        _ws_state
      ) do
    %__MODULE__{
      user: nil,
      user_id: user_id,
      guild_id: guild_id
    }
  end

  # Message Reaction Add events - only has user_id
  def from_payload(
        _consumer,
        %Nostrum.Struct.Event.MessageReactionAdd{user_id: user_id, guild_id: guild_id},
        _ws_state
      ) do
    %__MODULE__{
      user: nil,
      user_id: user_id,
      guild_id: guild_id
    }
  end

  # Message Reaction Remove events - only has user_id
  def from_payload(
        _consumer,
        %Nostrum.Struct.Event.MessageReactionRemove{user_id: user_id, guild_id: guild_id},
        _ws_state
      ) do
    %__MODULE__{
      user: nil,
      user_id: user_id,
      guild_id: guild_id
    }
  end

  # Guild Member events - tuple with {guild_id, member}
  def from_payload(
        _consumer,
        {guild_id, %Nostrum.Struct.Guild.Member{user_id: user_id}},
        _ws_state
      )
      when is_integer(guild_id) do
    %__MODULE__{
      user: nil,
      user_id: user_id,
      guild_id: guild_id
    }
  end

  # Guild Member Update - tuple with {guild_id, old_member, new_member}
  def from_payload(
        _consumer,
        {guild_id, _old, %Nostrum.Struct.Guild.Member{user_id: user_id}},
        _ws_state
      )
      when is_integer(guild_id) do
    %__MODULE__{
      user: nil,
      user_id: user_id,
      guild_id: guild_id
    }
  end

  # Thread events may have member field with user info
  def from_payload(_consumer, %{member: %{user: user}, guild_id: guild_id}, _ws_state) do
    %__MODULE__{
      user: user,
      user_id: user.id,
      guild_id: guild_id
    }
  end

  # Generic fallback - try to extract whatever we can find
  def from_payload(_consumer, payload, _ws_state) do
    user = extract_user(payload)
    user_id = extract_user_id(payload, user)
    guild_id = extract_guild_id(payload)

    %__MODULE__{
      user: user,
      user_id: user_id,
      guild_id: guild_id
    }
  end

  # Helper functions for generic extraction
  defp extract_user(payload) do
    cond do
      Map.has_key?(payload, :user) && is_struct(payload.user, Nostrum.Struct.User) ->
        payload.user

      Map.has_key?(payload, :author) && is_struct(payload.author, Nostrum.Struct.User) ->
        payload.author

      Map.has_key?(payload, :member) && Map.has_key?(payload.member, :user) ->
        payload.member.user

      true ->
        nil
    end
  end

  defp extract_user_id(payload, user) do
    cond do
      user != nil ->
        user.id

      Map.has_key?(payload, :user_id) ->
        payload.user_id

      Map.has_key?(payload, :member) && Map.has_key?(payload.member, :user_id) ->
        payload.member.user_id

      true ->
        nil
    end
  end

  defp extract_guild_id(payload) do
    Map.get(payload, :guild_id)
  end
end
