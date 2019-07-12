defmodule Certbot.SSL do
  @moduledoc """
  Utility functions to deal with ssl and generating private keys

  """
  @subject_keys %{
    common_name: "CN",
    country_name: "C",
    locality_name: "L",
    organization_name: "O",
    organizational_unit: "OU",
    state_or_province: "ST"
  }

  @rsa_key_sizes [2048, 3072, 4096]
  # https://tools.ietf.org/search/rfc4492#appendix-A
  @ec_curves [:secp256r1, :secp384r1]

  def generate_key({:rsa, size}) when size in @rsa_key_sizes do
    X509.PrivateKey.new_rsa(size)
  end

  def generate_key({:ec, curve}) when curve in @ec_curves do
    X509.PrivateKey.new_ec(curve)
  end

  def convert_private_key_to_der(key) do
    X509.PrivateKey.to_der(key)
  end

  def convert_private_key_to_pem(key) do
    X509.PrivateKey.to_pem(key)
  end

  def generate_csr(private_key, subject) do
    private_key |> X509.CSR.new(format_subject(subject)) |> X509.CSR.to_der()
  end

  defp format_subject(subject) do
    subject
    |> Enum.map(fn {k, v} -> "/#{@subject_keys[k]}=#{v}" end)
    |> Enum.join()
  end
end
