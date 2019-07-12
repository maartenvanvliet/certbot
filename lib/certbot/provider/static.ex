defmodule Certbot.Provider.Static do
  @moduledoc """
  Static certificate provider

  Expects a `certificates` keyword with a map of hostnames as keys and
  `%Certbot.Certificate{}` structs as values.

  Also an example of a simple certificate provider.

  ```elixir
  defmodule Myapp.StaticProvider do
    use Certbot.Provider.Acme,
      certificates: %{
        "example.com" => %Certbot.Certificate{
          cert: cert_der,
          key: {:RSAPrivateKey, key_der}
        }
      }
  end
  ```
  """

  defmacro __using__(opts) do
    quote location: :keep do
      @behaviour Certbot.Provider
      @defaults unquote(opts)

      alias Certbot.Provider.Static

      def get_by_hostname(hostname, opts \\ []) do
        opts = Keyword.merge(@defaults, opts)

        Static.get_by_hostname(hostname, opts)
      end
    end
  end

  @spec get_by_hostname(binary, keyword) :: nil | Certbot.Certificate.t()
  def get_by_hostname(hostname, opts \\ []) do
    certificates = Keyword.fetch!(opts, :certificates)

    case Map.get(certificates, hostname) do
      %Certbot.Certificate{} = certificate -> certificate
      _ -> nil
    end
  end
end
