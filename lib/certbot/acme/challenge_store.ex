defmodule Certbot.Acme.ChallengeStore do
  @moduledoc """
  Behaviour for storing and finding challenges

  Implement this behaviour for a challengestore based on another persistence
  mechanism.
  """
  @callback find_by_token(token :: String.t()) ::
              {:ok, challenge :: Certbot.Challenge.t()} | {:error, String.t()}

  @callback insert(challenge :: Certbot.Challenge.t()) :: :ok
end
