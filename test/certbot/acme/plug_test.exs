defmodule Certbot.Acme.PlugTest do
  use ExUnit.Case

  alias Certbot.Acme

  defmodule TestChallengeStore do
    @behaviour Certbot.Acme.ChallengeStore

    @impl true
    def find_by_token("some-token") do
      {:ok,
       %Certbot.Acme.Challenge{
         token: "some-token"
       }}
    end

    def find_by_token(_) do
      nil
    end

    @impl true
    def insert(_challenge) do
      :ok
    end
  end

  test "returns thumbprint for known token" do
    conn = test_token_conn("some-token")
    assert conn.status == 200
    assert conn.resp_body == "some-token.v5Co8pJG2fo_hBcdhEzpj_DSEcev76KkbFQkJRiu-Cg"
  end

  test "returns 404 for unknown token" do
    conn = test_token_conn("unknown-token")
    assert conn.status == 404
    assert conn.resp_body == "Not found"
  end

  test "passes plug for other paths" do
    conn = test_token_conn("unknown-token", "/other-path")
    assert conn.halted == false
  end

  defp test_token_conn(token, path \\ "/.well-known/acme-challenge/") do
    jwk =
      "test/fixtures/selfsigned_key.pem"
      |> File.read!()
      |> JOSE.JWK.from_pem()
      |> JOSE.JWK.to_map()

    opts = Acme.Plug.init(jwk: jwk, challenge_store: TestChallengeStore)

    Plug.Test.conn(:get, path <> token) |> Acme.Plug.call(opts)
  end
end
