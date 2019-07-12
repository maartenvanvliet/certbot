defmodule Certbot do
  @external_resource "./README.md"
  @moduledoc """
  #{File.read!("./README.md") |> String.split("-----", parts: 2) |> List.last()}
  """

  defmacro __using__(opts) do
    quote location: :keep do
      @defaults unquote(opts)

      @client Certbot.Acme.Client
      @doc """
      Callback called by the SSL layer in OTP
      See http://erlang.org/doc/man/ssl.html
      Returns the der encoded certificate, public/private key pair for the
      ssl handshake
      """
      def sni_fun(hostname) do
        opts = @defaults

        Certbot.sni_fun(List.to_string(hostname), opts)
      end

      use GenServer

      def start_link(opts, name \\ @client) do
        opts = Keyword.merge(@defaults, opts)
        Certbot.start_link(opts, name)
      end

      def init(init_arg) do
        {:ok, init_arg}
      end

      def authorize(hostname) do
        GenServer.call(@client, {:authorize, hostname})
      end

      def respond_challenge(challenge) do
        GenServer.call(@client, {:respond_challenge, challenge})
      end

      def new_certificate(csr) do
        GenServer.call(@client, {:new_certificate, csr})
      end

      def get_certificate(csr) do
        GenServer.call(@client, {:get_certificate, csr})
      end
    end
  end

  def start_link(opts, name \\ Certbot.Acme.Client) do
    config = Certbot.Config.new(opts)
    GenServer.start_link(Certbot.Acme.Client, config, name: name)
  end

  def sni_fun(hostname, opts) do
    config = Certbot.Config.new(opts)

    case config.certificate_provider.get_by_hostname(hostname) do
      %Certbot.Certificate{cert: cert, key: key} = certificate ->
        serial = Certbot.Certificate.hex_serial(certificate)
        config.logger.log(:info, "Serving #{hostname} with certificate #{serial}")
        # Serve the dynamic cert
        [
          cert: cert,
          key: key
        ]

      # Do nothing, serves up the static tls config configured for your domains if set
      # will fail on other domains but nothing we can do
      _ ->
        config.logger.log(:info, "No certificate found for #{hostname}")
        []
    end
  end
end
