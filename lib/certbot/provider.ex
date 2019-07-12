defmodule Certbot.Provider do
  @moduledoc """
  Behaviour used for providing certficates by a given hostname.
  """
  @callback get_by_hostname(hostname :: String.t()) :: Certbot.Certificate.t() | nil
end
