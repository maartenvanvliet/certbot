defmodule CertbotTest do
  use ExUnit.Case

  defmodule TestProvider do
    def get_by_hostname("example.com") do
      Helper.build_certificate()
    end

    def get_by_hostname("unknown.com") do
      nil
    end
  end

  defmodule TestStaticClient do
    @jwk "test/fixtures/selfsigned_key.pem"
         |> File.read!()
         |> JOSE.JWK.from_pem()
         |> JOSE.JWK.to_map()

    use Certbot,
      jwk: @jwk,
      email: "mailto:test@example.com",
      certificate_provider: CertbotTest.TestProvider,
      logger: NoopLogger
  end

  test "returns certificate/key as list for known hostname" do
    cert = Helper.build_certificate()
    assert [cert: cert.cert, key: cert.key] == TestStaticClient.sni_fun('example.com')
  end

  test "returns empty list for unknown hostname" do
    assert [] == TestStaticClient.sni_fun('unknown.com')
  end
end
