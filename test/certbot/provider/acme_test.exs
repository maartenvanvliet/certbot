defmodule Certbot.Provider.AcmeTest do
  use ExUnit.Case
  doctest Certbot.Provider.Acme

  alias Certbot.Provider.AcmeTest

  defmodule TestAcme do
    use Certbot.Provider.Acme,
      certificate_store: AcmeTest.TestCertificateStore,
      acme_client: AcmeTest.TestClient,
      challenge_store: AcmeTest.TestChallengeStore,
      logger: NoopLogger
  end

  defmodule TestClient do
    def authorize("bogus.com") do
      authorization = %Certbot.Acme.Authorization{
        challenges: [
          %Certbot.Acme.Challenge{
            status: "pending",
            token: "some_token",
            type: "http-01",
            uri: nil
          }
        ]
      }

      {:ok, authorization}
    end

    def respond_challenge(_challenge) do
      {:ok,
       %Certbot.Acme.Challenge{
         status: "valid",
         token: "some_token",
         type: "http-01",
         uri: nil
       }}
    end

    def new_certificate(_csr) do
      {:ok, "http://example.com/certificate"}
    end

    def get_certificate(url) do
      send(self(), url)
      {:ok, Helper.der_cert()}
    end
  end

  defmodule TestCertificateStore do
    @behaviour Certbot.CertificateStore

    @impl true
    def find_certificate("test.com"), do: Helper.build_certificate()

    def find_certificate("bogus.com"), do: nil

    @impl true
    def insert(hostname, certificate) do
      send(self(), {:insert_certificate, hostname, certificate})
    end
  end

  defmodule TestChallengeStore do
    @behaviour Certbot.Acme.ChallengeStore

    @impl true
    def find_by_token(_), do: nil

    @impl true
    def insert(challenge) do
      send(self(), challenge)
    end
  end

  test "returns certificate for already stored hostname" do
    assert %Certbot.Certificate{} = certificate = TestAcme.get_by_hostname("test.com")
    assert certificate == Helper.build_certificate()
  end

  test "returns nil for unknown hostname" do
    assert %Certbot.Certificate{} = TestAcme.get_by_hostname("bogus.com")

    assert_received(%Certbot.Acme.Challenge{
      status: "pending",
      token: "some_token",
      type: "http-01",
      uri: nil
    })

    assert_received("http://example.com/certificate")

    assert_received({:insert_certificate, "bogus.com", inserted_certificate})
    assert %Certbot.Certificate{} = inserted_certificate
  end
end
