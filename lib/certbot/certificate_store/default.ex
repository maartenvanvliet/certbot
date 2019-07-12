defmodule Certbot.CertificateStore.Default do
  @moduledoc """
  Default store for certificates. Stores certificates in an ets table.

  This store won't work when you have multiple servers as the certificates will
  only be stored on one server.
  """
  @behaviour Certbot.CertificateStore

  use GenServer

  @table :certbot_certificate_store

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @table, name: __MODULE__)
  end

  @impl true
  def init(table) do
    table =
      :ets.new(table, [
        :named_table,
        :set,
        :public,
        read_concurrency: true,
        write_concurrency: true
      ])

    {:ok, table}
  end

  @spec find_certificate(String.t()) :: {:ok, Certbot.Challenge.t()} | {:error, String.t()}
  @impl true
  def find_certificate(hostname) do
    case :ets.lookup(@table, hostname) do
      [{^hostname, certificate}] -> certificate
      _ -> nil
    end
  end

  @impl true
  def insert(hostname, certificate) do
    :ets.insert(@table, {hostname, certificate})
    :ok
  end
end
