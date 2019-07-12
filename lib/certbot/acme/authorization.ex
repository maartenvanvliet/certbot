defmodule Certbot.Acme.Authorization do
  @moduledoc """
  Module for handling an `Acme.Authorization` response, converted from an
  `%Acme.Authorization{}` struct
  """
  @type t :: %__MODULE__{
          status: String.t(),
          identifier: any(),
          expires: any,
          challenges: list(Certbot.Acme.t())
        }

  defstruct [:status, :identifier, :expires, :challenges]

  alias Certbot.Acme.Challenge

  @types ["http-01", "dns-01", "tls-sni-01"]
  @spec from_map(Acme.Authorization.t()) :: Certbot.Acme.Authorization.t()
  def from_map(%Acme.Authorization{
        status: status,
        expires: expires,
        identifier: identifier,
        challenges: challenges
      }) do
    %__MODULE__{
      status: status,
      expires: expires,
      identifier: identifier,
      challenges: Enum.map(challenges, &Challenge.from_struct/1)
    }
  end

  @doc """
  Fetch specific challenge by type from an authorization struct

  Possible types: #{@types |> Enum.map(&"`#{&1}` ")}

  ## Example
  ```
  iex> Certbot.Acme.Authorization.fetch_challenge(%Certbot.Acme.Authorization{challenges: []}, "http-01")
  nil

  iex> challenge = %Certbot.Acme.Challenge{type: "http-01"}
  iex> Certbot.Acme.Authorization.fetch_challenge(%Certbot.Acme.Authorization{challenges: [challenge]}, "http-01")
  %Certbot.Acme.Challenge{
          status: nil,
          token: nil,
          type: "http-01",
          uri: nil
        }
  """
  @spec fetch_challenge(Certbot.Acme.Authorization.t(), String.t()) :: any
  def fetch_challenge(%__MODULE__{challenges: challenges}, type)
      when type in ["http-01", "dns-01", "tls-sni-01"] do
    Enum.find(challenges, &(&1.type == to_string(type)))
  end
end
