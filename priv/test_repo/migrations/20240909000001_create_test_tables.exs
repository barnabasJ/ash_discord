defmodule TestApp.Repo.Migrations.CreateTestTables do
  use Ecto.Migration

  def up do
    create table("discord_guilds", primary_key: false) do
      add(:id, :binary_id, null: false, primary_key: true)
      add(:discord_id, :bigint, null: false)
      add(:name, :text, null: false)
      add(:description, :text)
      add(:icon, :text)

      timestamps()
    end

    create unique_index("discord_guilds", [:discord_id])

    create table("discord_users", primary_key: false) do
      add(:id, :binary_id, null: false, primary_key: true)
      add(:discord_id, :bigint, null: false)
      add(:username, :text, null: false)
      add(:discriminator, :text)
      add(:avatar, :text)
      add(:email, :text)

      timestamps()
    end

    create unique_index("discord_users", [:discord_id])

    create table("discord_messages", primary_key: false) do
      add(:id, :binary_id, null: false, primary_key: true)
      add(:discord_id, :bigint, null: false)
      add(:content, :text, null: false)
      add(:channel_id, :bigint)
      add(:author_id, :bigint)
      add(:guild_id, :bigint)
      add(:timestamp, :utc_datetime)
      add(:edited_timestamp, :utc_datetime)

      timestamps()
    end

    create unique_index("discord_messages", [:discord_id])
    create index("discord_messages", [:guild_id])
    create index("discord_messages", [:author_id])

    create table("discord_guild_members", primary_key: false) do
      add(:id, :binary_id, null: false, primary_key: true)
      add(:guild_id, :bigint, null: false)
      add(:user_id, :bigint, null: false)
      add(:nick, :text)
      add(:roles, {:array, :bigint}, default: [])
      add(:joined_at, :utc_datetime)

      timestamps()
    end

    create unique_index("discord_guild_members", [:guild_id, :user_id])
  end

  def down do
    drop table("discord_guild_members")
    drop table("discord_messages")
    drop table("discord_users")
    drop table("discord_guilds")
  end
end