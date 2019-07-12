defmodule Certbot.Logger do
  @moduledoc """
  Module and behaviour to log events
  """

  require Logger
  @callback log(:debug | :error | :info | :warn, any) :: :ok | {:error, any}
  @spec log(:debug | :error | :info | :warn, any) :: :ok | {:error, any}
  def log(level, chardata_or_fun), do: Logger.log(level, chardata_or_fun)
end
