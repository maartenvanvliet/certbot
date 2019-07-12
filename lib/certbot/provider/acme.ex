defmodule Certbot.Provider.Acme do
  @moduledoc """
  Certificate provider for the Acme protocol

  When a request is made for a hostname, the provider will look into the
  certificate store (`Certbot.CertificateStore`) to see whether it has a
  certificate for that hostname.

  If so, it will return the certificate.

  If not, it will try to request a certificate using the acme client. This is done
  by retrieving an authorization, which has challenges. We need to prove to the acme
  server that we own the hostname.

  One of these challenges can be done over http. We use this one to prove ownership.
  The challenge is stored in the challenge store (`Certbot.Acme.ChallengeStore`),
  then the Acme server is asked to verify the challenge. The `Certbot.Acme.Plug`
  verifies the challenge by using the store.

  Next step is to  build a Certificate Signing Request (`csr`) and send this to
  the Acme server. In the response there will be a url where the signed certificate
  can be retrieved from the Acme server.

  The downloaded certificate is used for the serving the request, and  also stored
  in the certificate store for subsequent requests.

  ## Example
  ```
    use Certbot.Provider.Acme,
      acme_client: YourApp.Certbot,
      certificate_store: Certbot.CertificateStore.Default,
      challenge_store: Certbot.ChallengeStore.Default
  ```

  For the options that can be given to the `use` macro, see `Certbot.Provider.Acme.Config`
  """
  defmodule Config do
    @moduledoc """
    Configuration for the `Certbot.Provider.Acme` certificate provider.

      - `:acme_client` -- Client implementing `use Certbot`, e.g. `Myapp.Certbot`
      - `:certificate_store` -- Module used to store certificates,
      - `:challenge_store` -- Module used to store certificates,
      - `:logger` -- Module to log events, defaults to `Certbot.Logger`,
      - `:key_algorithm` -- Algorithm used to generate keys for certificates,
        defaults to `{:ec, :secp384r1}`. Can also be e.g. `{:rsa, 2048}`

    """
    defstruct [:certificate_store, :challenge_store, :acme_client, :logger, :key_algorithm]

    def new(opts \\ []) do
      %__MODULE__{
        acme_client: Keyword.fetch!(opts, :acme_client),
        certificate_store: Keyword.fetch!(opts, :certificate_store),
        challenge_store: opts[:challenge_store],
        logger: opts[:logger] || Certbot.Logger,
        key_algorithm: opts[:key_algorithm] || {:ec, :secp384r1}
      }
    end
  end

  defmacro __using__(opts) do
    quote location: :keep do
      @defaults unquote(opts)

      @behaviour Certbot.Provider

      alias Certbot.Provider.Acme

      def get_by_hostname(hostname, opts \\ []) do
        opts = Keyword.merge(@defaults, opts)

        Acme.get_by_hostname(hostname, opts)
      end
    end
  end

  alias Certbot.Acme.Authorization
  alias Certbot.Provider.Acme.Config

  def get_by_hostname(hostname, opts) do
    config = Config.new(opts)
    config.logger.log(:info, "Checking store for certificate for #{hostname}")

    case config.certificate_store.find_certificate(hostname) do
      %Certbot.Certificate{} = certificate ->
        serial = Certbot.Certificate.hex_serial(certificate)
        config.logger.log(:info, "Found certificate (#{serial}) for #{hostname} in store")
        certificate

      _ ->
        config.logger.log(
          :info,
          "No certificate found in store, requesting certificate for #{hostname}"
        )

        case authorize_hostname(hostname, config) do
          {:ok, certificate} ->
            serial = Certbot.Certificate.hex_serial(certificate)

            config.logger.log(
              :info,
              "Retrieved certificate (#{serial}) for #{hostname}, storing it"
            )

            config.certificate_store.insert(hostname, certificate)

            certificate

          {:error, error} ->
            config.logger.log(:error, inspect(error))
            error
        end
    end
  end

  defp authorize_hostname(hostname, config) do
    case config.acme_client.authorize(hostname) do
      {:ok, authorization} ->
        challenge = Authorization.fetch_challenge(authorization, "http-01")
        config.logger.log(:info, "Storing challenge in store for #{hostname}")
        config.challenge_store.insert(challenge)

        check_challenge(challenge, hostname, config)

      {:error, error} ->
        {:error, error}
    end
  end

  defp check_challenge(challenge, hostname, config) do
    config.logger.log(:info, "Checking challenge #{challenge.uri} for #{hostname}")

    case config.acme_client.respond_challenge(challenge) do
      {:ok, %{status: "valid"}} ->
        get_certificate(hostname, config)

      # should validate edge cases here
      # the 10ms is completely arbitrary...
      {:ok, _challenge_response} ->
        Process.sleep(10)

        check_challenge(challenge, hostname, config)

      {:error, error} ->
        config.logger.error(inspect(error))

        nil
    end
  end

  defp get_certificate(hostname, config) do
    key = Certbot.SSL.generate_key(config.key_algorithm)
    algorithm = elem(key, 0)
    csr = Certbot.SSL.generate_csr(key, %{common_name: hostname})

    der_key = Certbot.SSL.convert_private_key_to_der(key)

    with {:ok, url} <- config.acme_client.new_certificate(csr),
         {:ok, certificate} <- config.acme_client.get_certificate(url) do
      certificate = Certbot.Certificate.build(certificate, {algorithm, der_key})

      {:ok, certificate}
    else
      error -> error
    end
  end
end
