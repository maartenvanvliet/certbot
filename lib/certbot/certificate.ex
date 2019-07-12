defmodule Certbot.Certificate do
  @moduledoc """
  The module provides utility functions to deal with the serial and validity
  timestamps of a certificate as well as being a struct to store certificate/keys
  """

  @type t :: %__MODULE__{
          cert: binary(),
          key: {atom(), binary()}
        }

  defstruct [:cert, :key]

  @algo [:RSAPrivateKey, :ECPrivateKey]

  @spec build(binary, {:ECPrivateKey, binary} | {:RSAPrivateKey, binary}) ::
          Certbot.Certificate.t()
  @doc """
  Build struct to store a certificate in der format and its private key

  For example, to generate a
  ```elixir
      cert_file = File.read!("priv/cert/selfsigned.pem")
      key_file = File.read!("priv/cert/selfsigned_key.pem")

      [certificate] = :public_key.pem_decode(cert_file)
      cert = :public_key.pem_entry_decode(certificate)
      cert = :public_key.der_encode(:Certificate, cert)

      [key] = :public_key.pem_decode(key_file)
      key = :public_key.pem_entry_decode(key)
      der_key = :public_key.der_encode(:RSAPrivateKey, key)

      Certbot.Certificate.build(cert, {:RSAPrivateKey, der_key})
  ```
  """
  def build(cert, {algo, der_key})
      when algo in @algo and is_binary(cert) and is_binary(der_key) do
    %__MODULE__{
      cert: cert,
      key: {algo, der_key}
    }
  end

  @spec serial(Certbot.Certificate.t()) :: non_neg_integer
  @doc """
  Get integer serial number of the certicate

  ```
  iex> Certbot.Certificate.serial(build_certificate())
  18163034872729040431
  ```
  """
  def serial(%Certbot.Certificate{cert: cert}) do
    cert |> X509.Certificate.from_der!() |> X509.Certificate.serial()
  end

  @doc """
  Get hexadecimal serial number of the certicate

  This is what is visible when inspecting a certificate in the browser

  ## Example
  ```
  iex> Certbot.Certificate.hex_serial(build_certificate())
  "FC100FFC200BF62F"
  ```
  """
  @spec hex_serial(Certbot.Certificate.t()) :: String.t()
  def hex_serial(%Certbot.Certificate{} = cert) do
    cert |> serial() |> Integer.to_string(16)
  end

  @doc """
  Get DateTime of the date the certificate was given out

  ## Example
  ```
  iex> Certbot.Certificate.valid_from(build_certificate())
  ~U[2019-07-09 00:00:00Z]
  ```
  """
  @spec valid_from(Certbot.Certificate.t()) :: DateTime.t()
  def valid_from(%Certbot.Certificate{cert: cert}) do
    validity(:from, cert) |> to_string |> to_datetime
  end

  @doc """
  Get DateTime of the date the certificate will be valid until

  ## Example
  ```
  iex> Certbot.Certificate.valid_until(build_certificate())
  ~U[2020-07-09 00:00:00Z]
  ```
  """
  @spec valid_until(Certbot.Certificate.t()) :: DateTime.t()
  def valid_until(%Certbot.Certificate{cert: cert}) do
    validity(:until, cert) |> to_string |> to_datetime
  end

  # "190710122644Z"
  defp to_datetime(
         <<year::binary-size(2)>> <>
           <<month::binary-size(2)>> <>
           <<day::binary-size(2)>> <>
           <<hour::binary-size(2)>> <>
           <<minute::binary-size(2)>> <> <<second::binary-size(2)>> <> _rest
       ) do
    # No century info present, hack to fix
    year = String.to_integer(year) + 2000

    {{year, String.to_integer(month), String.to_integer(day)},
     {String.to_integer(hour), String.to_integer(minute), String.to_integer(second)}}
    |> NaiveDateTime.from_erl!()
    |> DateTime.from_naive!("Etc/UTC")
  end

  defp validity(:from, cert) do
    {:Validity, {:utcTime, from}, _} = validity(cert)
    from
  end

  defp validity(:until, cert) do
    {:Validity, _, {:utcTime, until}} = validity(cert)
    until
  end

  defp validity(cert) do
    cert |> X509.Certificate.from_der!() |> X509.Certificate.validity()
  end
end
