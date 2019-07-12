defmodule Certbot.Error do
  @moduledoc """
  Struct to store errors
  """
  defstruct [:detail, :status, :type]

  @doc """
  Convert structs of the same shape, to a Certbot.Error struct.

  E.g. Acme.Error
  """
  def from_struct(map) do
    map = Map.from_struct(map)
    struct(__MODULE__, map)
  end
end
