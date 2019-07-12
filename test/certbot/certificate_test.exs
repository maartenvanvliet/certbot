defmodule Certbot.CertificateTest do
  use ExUnit.Case
  doctest Certbot.Certificate

  def build_certificate do
    Helper.build_certificate()
  end
end
