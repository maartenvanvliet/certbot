defmodule Certbot.Acme.Plug do
  @moduledoc """
  Plug used to intercept challenge verification calls on the request path
  `/.well-known/acme-challenge/<token>`.

  The plug can be placed early in the pipeline. When using Phoenix, it should
  be placed before your router in your `endpoint.ex`.

  If you plan on redirecting http to https using Plug.SSL, place it after this plug.
  `Certbot.Acme.Plug` needs to work over http.

  It requires two options.
   - `:challenge_store` -- The challenge store used, so when a verication call
  comes in, it can check whether it knows the token. It needs to be the same store
  where the `Certbot.Provider.Acme` provider stores the challenges.
   - `:jwk` -- A jwk map, see below for an example on how to generate one from
   a private key.

  ## Example
  ```
  @jwk "priv/cert/selfsigned_key.pem" |> File.read!() |> JOSE.JWK.from_pem() |> JOSE.JWK.to_map()

  plug Certbot.Acme.Plug, challenge_store: Certbot.ChallengeStore.Default, jwk: @jwk
  ```

  """
  alias Certbot.Acme.Challenge

  @spec init(any) :: {atom, any}
  def init(opts) do
    challenge_store = Keyword.fetch!(opts, :challenge_store)
    jwk = Keyword.fetch!(opts, :jwk)

    validate_jwk!(jwk)

    {challenge_store, jwk}
  end

  @spec call(Plug.Conn.t(), {atom, any}) :: Plug.Conn.t()
  def call(conn, {challenge_store, jwk}) do
    case conn.request_path do
      "/.well-known/acme-challenge/" <> token ->
        reply_challenge(conn, token, {challenge_store, jwk})

      _ ->
        conn
    end
  end

  defp reply_challenge(conn, token, {challenge_store, jwk}) do
    case challenge_store.find_by_token(token) do
      {:ok, challenge} ->
        authorization = Challenge.authorization(challenge, jwk)

        conn
        |> Plug.Conn.send_resp(200, authorization)
        |> Plug.Conn.halt()

      _ ->
        conn
        |> Plug.Conn.send_resp(404, "Not found")
        |> Plug.Conn.halt()
    end
  end

  defp validate_jwk!(jwk) do
    %JOSE.JWK{} = JOSE.JWK.from_map(jwk)
    jwk
  rescue
    _ -> reraise ArgumentError, "Invalid jwk supplied to `Certbot.Acme.Plug`"
  end
end
