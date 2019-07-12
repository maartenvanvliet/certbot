ExUnit.start()

defmodule Helper do
  def build_certificate do
    key_file = File.read!("test/fixtures/selfsigned_key.pem")

    [key] = :public_key.pem_decode(key_file)
    key = :public_key.pem_entry_decode(key)
    der_key = :public_key.der_encode(:RSAPrivateKey, key)

    Certbot.Certificate.build(der_cert(), {:RSAPrivateKey, der_key})
  end

  def der_cert do
    cert_file = File.read!("test/fixtures/selfsigned.pem")
    [certificate] = :public_key.pem_decode(cert_file)
    cert = :public_key.pem_entry_decode(certificate)
    :public_key.der_encode(:Certificate, cert)
  end
end

defmodule NoopLogger do
  @behaviour Certbot.Logger
  def log(_, _), do: nil
end
