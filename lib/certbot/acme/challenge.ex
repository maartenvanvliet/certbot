defmodule Certbot.Acme.Challenge do
  @moduledoc """
  Struct with utility functions for dealing with Acme Challenges
  """
  @type t :: %__MODULE__{
          token: String.t(),
          status: String.t(),
          type: String.t(),
          uri: String.t()
        }

  defstruct [:token, :status, :type, :uri]

  @doc """
  Return authorization token given a challenge and the jwk used to generate it

  ## Example
  ```
  iex> jwk = "test/fixtures/selfsigned_key.pem" |> File.read!() |> JOSE.JWK.from_pem() |> JOSE.JWK.to_map()
  iex> Certbot.Acme.Challenge.authorization("some_token", jwk)
  "some_token.v5Co8pJG2fo_hBcdhEzpj_DSEcev76KkbFQkJRiu-Cg"
  ```
  """
  @spec authorization(binary | %{token: any}, any) :: String.t()
  def authorization(token, jwk) when is_binary(token) do
    thumbprint = JOSE.JWK.thumbprint(jwk)
    "#{token}.#{thumbprint}"
  end

  def authorization(%__MODULE__{token: token}, jwk) do
    __MODULE__.authorization(token, jwk)
  end

  @doc """
  Convert structs of the same shape, to a `Certbot.Acme.Challenge` struct.

  ## Example
  ```
  iex> Certbot.Acme.Challenge.from_struct(%Acme.Challenge{type: "http-01"})
  %Certbot.Acme.Challenge{
              status: nil,
              token: nil,
              type: "http-01",
              uri: nil
            }
  ```
  """
  def from_struct(map) do
    map = Map.from_struct(map)
    struct(__MODULE__, map)
  end
end
