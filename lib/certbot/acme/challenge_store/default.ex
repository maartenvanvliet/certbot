defmodule Certbot.Acme.ChallengeStore.Default do
  @moduledoc """
  Default Acme.ChallengeStore

  Used to store challenges provided by the Acme server. This is a simple genserver,
  if you have multiple servers running the challenges won't be distributed among
  them so the challenges will fail.

  To counter this you'll need to reimplement this store with another one, e.g.
  based on mnesia or redis, and should implement the Certbot.Acme.ChallengeStore
  behaviour

  """
  @behaviour Certbot.Acme.ChallengeStore

  use GenServer

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:insert, challenge}, state) do
    {:noreply, Map.put(state, challenge.token, challenge)}
  end

  @impl true
  def handle_call({:find_by_token, token}, _from, state) do
    result =
      case Map.get(state, token, nil) do
        nil -> {:error, "No such challenge"}
        challenge -> {:ok, challenge}
      end

    {:reply, result, state}
  end

  @spec find_by_token(String.t()) :: {:ok, Certbot.Challenge.t()} | {:error, String.t()}
  @impl true
  def find_by_token(token) do
    GenServer.call(__MODULE__, {:find_by_token, token})
  end

  @impl true
  def insert(challenge) do
    GenServer.cast(__MODULE__, {:insert, challenge})
  end
end
