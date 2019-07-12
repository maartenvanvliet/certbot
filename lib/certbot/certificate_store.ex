defmodule Certbot.CertificateStore do
  @moduledoc """
  Stores and look ups certificates by hostname

  Behaviour that can be reimplemented for other storage mechanisms, e.g. redis,
  database or mnesia

  """
  @callback find_certificate(hostname :: String.t()) ::
              Certbot.Certificate.t() | nil

  @callback insert(hostname :: String.t(), certificate :: Certbot.Certificate.t()) ::
              :ok
end
