defmodule AshDiscord.Context do
  @moduledoc """
  Discord event context for passing through Ash operations.

  This context carries Discord-specific information like the consumer module,
  guild context, user information, and WebSocket state. It implements the
  `Ash.Scope.ToOpts` protocol to provide actor, tenant, and context information
  to Ash operations.
  """

  defstruct [
    :consumer,
    :resource,
    :user,
    :user_id,
    :guild_id
  ]

  @type t :: %__MODULE__{
          consumer: module(),
          resource: Ash.Resource.t(),
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
  Extracts user information from various Discord event payloads.
  Handles both struct-based payloads and tuple-based payloads.
  """
  @spec extract_user(payload :: AshDiscord.Consumer.Payload.t()) :: Nostrum.Struct.User.t() | nil
  def extract_user(payload) when is_tuple(payload) do
    # Handle tuple payloads like {guild_id, user} or {guild_id, old, new}
    case payload do
      {_guild_id, %Nostrum.Struct.User{} = user} -> user
      {_guild_id, %Nostrum.Struct.Guild.Member{}} -> nil
      {_guild_id, _old, %Nostrum.Struct.Guild.Member{}} -> nil
      {%Nostrum.Struct.User{} = old_user, _new_user} -> old_user
      _ -> nil
    end
  end

  def extract_user(payload) when is_map(payload) do
    cond do
      Map.has_key?(payload, :user) && is_struct(payload.user, Nostrum.Struct.User) ->
        payload.user

      Map.has_key?(payload, :author) && is_struct(payload.author, Nostrum.Struct.User) ->
        payload.author

      Map.has_key?(payload, :member) && is_map(payload.member) &&
          Map.has_key?(payload.member, :user) ->
        payload.member.user

      true ->
        nil
    end
  end

  def extract_user(_payload), do: nil

  @doc """
  Extracts user ID from various Discord event payloads.
  Prefers the user struct's ID if available, otherwise extracts from payload fields.
  """
  @spec extract_user_id(
          payload :: AshDiscord.Consumer.Payload.t(),
          user :: Nostrum.Struct.User.t() | nil
        ) :: Nostrum.Snowflake.t() | nil
  def extract_user_id(payload, user) when is_tuple(payload) do
    if user != nil do
      user.id
    else
      case payload do
        {_guild_id, %Nostrum.Struct.Guild.Member{user_id: user_id}} -> user_id
        {_guild_id, _old, %Nostrum.Struct.Guild.Member{user_id: user_id}} -> user_id
        _ -> nil
      end
    end
  end

  def extract_user_id(payload, user) when is_map(payload) do
    cond do
      user != nil ->
        user.id

      Map.has_key?(payload, :user_id) ->
        payload.user_id

      Map.has_key?(payload, :member) && is_map(payload.member) &&
          Map.has_key?(payload.member, :user_id) ->
        payload.member.user_id

      true ->
        nil
    end
  end

  def extract_user_id(_payload, user) when user != nil, do: user.id
  def extract_user_id(_payload, _user), do: nil

  @doc """
  Extracts guild ID from Discord event payloads.
  Handles both struct-based payloads and tuple-based payloads.
  """
  @spec extract_guild_id(payload :: AshDiscord.Consumer.Payload.t()) ::
          Nostrum.Snowflake.t() | nil
  def extract_guild_id(payload) when is_tuple(payload) do
    case payload do
      {guild_id, _} when is_integer(guild_id) -> guild_id
      {guild_id, _, _} when is_integer(guild_id) -> guild_id
      _ -> nil
    end
  end

  def extract_guild_id(payload) when is_map(payload) do
    Map.get(payload, :guild_id)
  end

  def extract_guild_id(_payload), do: nil
end
