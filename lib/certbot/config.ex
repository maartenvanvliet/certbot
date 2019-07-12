defmodule Certbot.Config do
  @moduledoc """
  Configuration for Certbot

  These are the options supplied to `use Certbot, server: ""`

    - `:jwk` -- jwk for the account private key for the Acme client
    - `:email` -- email for the account for the Acme client e.g. `mailto:test@example.com`
    - `:certificate_provider` -- module that will responsible for getting certificates
    from the store, or requesting new certifictes
    - `:server` -- Server implementing the Acme protocol, most likely that you want the
  staging server `https://acme-staging.api.letsencrypt.org/` or the production server
  `https://acme-v01.api.letsencrypt.org`. Alternatively you can use another implemntation
  like Boulder or Pebble

  The jwk can be generated from a private key like this:
  ```elixir
  jwk = "priv/cert/selfsigned_key.pem"
       |> File.read!()
       |> JOSE.JWK.from_pem()
       |> JOSE.JWK.to_map()

  """
  @type t :: %__MODULE__{
          jwk: any(),
          server: String.t(),
          email: String.t(),
          logger: any(),
          certificate_provider: any()
        }

  defstruct [
    :jwk,
    :server,
    :email,
    :logger,
    :certificate_provider
  ]

  @spec new(nil | keyword) :: Certbot.Config.t()
  def new(opts \\ []) do
    %__MODULE__{
      jwk: validate_jwk!(opts[:jwk]),
      server: opts[:server] || "https://acme-v01.api.letsencrypt.org/",
      email: Keyword.fetch!(opts, :email),
      logger: opts[:logger] || Certbot.Logger,
      certificate_provider: Keyword.fetch!(opts, :certificate_provider)
    }
  end

  defp validate_jwk!({_, jwk}) do
    %JOSE.JWK{} = JOSE.JWK.from_map(jwk)
    jwk
  rescue
    _ -> reraise ArgumentError, "Invalid jwk supplied to `Certbot.Acme.Plug`"
  end

  defp validate_jwk!(jwk) do
    raise ArgumentError, "Invalid jwk `#{inspect(jwk)}` supplied to `Certbot.Acme.Plug`"
  end
end
