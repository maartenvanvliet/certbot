defmodule Certbot.Acme.Client do
  @moduledoc false
  use GenServer

  def init(config) do
    {:ok, conn} =
      Acme.Client.start_link(
        server: config.server,
        private_key: config.jwk
      )
      |> convert_error

    case config.email |> Acme.register() |> request(conn) do
      {:ok, registration} ->
        registration |> Acme.agree_terms() |> request(conn)

      {:error, %Acme.Error{status: 409}} ->
        {:ok, nil}

      {:error, error} ->
        error
    end

    {:ok, {config, conn}}
  end

  def handle_call({:authorize, hostname}, _from, {_config, conn} = state) do
    result = hostname |> Acme.authorize() |> request(conn) |> convert_authorization

    {:reply, result, state}
  end

  def handle_call({:respond_challenge, challenge}, _from, {_config, conn} = state) do
    challenge = struct(Acme.Challenge, Map.from_struct(challenge))

    result =
      challenge
      |> Acme.respond_challenge()
      |> request(conn)
      |> convert_authorization

    {:reply, result, state}
  end

  def handle_call({:new_certificate, csr}, _from, {_config, conn} = state) do
    result =
      csr
      |> Acme.new_certificate()
      |> request(conn)

    {:reply, result, state}
  end

  def handle_call({:get_certificate, url}, _from, {_config, conn} = state) do
    result =
      url
      |> Acme.get_certificate()
      |> request(conn)

    {:reply, result, state}
  end

  defp convert_error(result) do
    case result do
      {:error, %Acme.Error{} = error} -> {:error, Certbot.Error.from_struct(error)}
      result -> result
    end
  end

  defp convert_authorization(result) do
    case result do
      {:ok, %Acme.Authorization{} = authorization} ->
        {:ok, Certbot.Acme.Authorization.from_map(authorization)}

      error ->
        error
    end
  end

  defp request(request, conn) do
    request
    |> Acme.request(conn)
    |> convert_error
  end
end
