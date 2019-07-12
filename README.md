# Certbot
-----

Provide certificates for your Phoenix or Plug app using Letsencrypt.

This package should for now be considered a POC. Not everything is implemented
at the moment, most notably, certificate renewal.

You can also set your own Certificate Provider for your own functionality, or
to provide different certificates for different hostnames.

## Installation

The package can be installed
by adding `certbot` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:certbot, "~> 0.5.0"}
  ]
end
```

### Setting up Letsencrypt with Phoenix
From then on there are a few steps, we need to setup a certbot client, a store
for the certificates and a store for Acme challenges. Furthermore we need to setup
`Certbot.Acme.Plug` to verify Acme challenges over http.

### Certbot client
First, a certbot client is needed. We use a self generated private key to build 
into a JWK. If you have a Phoenix project, this can be generated with 
`mix phx.gen.cert`

Furthermore, we set an AcmeCertificateProvider
```elixir
defmodule Myapp.CertbotClient do
  @jwk "priv/cert/selfsigned_key.pem"
       |> File.read!()
       |> JOSE.JWK.from_pem()
       |> JOSE.JWK.to_map()

  use Certbot,
    certificate_provider: Myapp.AcmeCertificateProvider,
    jwk: @jwk,
    email: "mailto:test@example.com
end

defmodule Myapp.AcmeCertificateProvider do
  use Certbot.Provider.Acme,
    challenge_store: Certbot.Acme.ChallengeStore.Default,
    certificate_store: Certbot.CertificateStore.Default,
    acme_client: Myapp.CertbotClient
end
```

The `Myapp.CertbotClient` doubles as an Acme client, and therefore needs to be added 
to the supervision tree of your application. We use, the default challenge/certificate 
stores of the package, they also need to be added your application supervision 
tree. Note, there are downsides to the stores, see their docs for more info.

Your supervision tree will look something like this in a Phoenix project
```elixir
# application.ex

children = [
  # Start the Ecto repository
  Myapp.Repo,
  # Start the endpoint when the application starts
  MyappWeb.Endpoint,
  Myapp.CertbotClient,
  Certbot.Acme.ChallengeStore.Default,
  Certbot.CertificateStore.Default
]
```

In your `endpoint.ex` you should add `Certbot.Acme.Plug`, with the same challenge
store and `jwk`.

It should be added before the router, and before Plug.SSL if force SSL redirects 
are turned on.

```elixir
# endpoint.ex
@jwk "priv/cert/selfsigned_key.pem" |> File.read!() |> JOSE.JWK.from_pem() |> JOSE.JWK.to_map()

plug Certbot.Acme.Plug, challenge_store: Certbot.Acme.ChallengeStore.Default, jwk: @jwk
plug MyappWeb.Router
```

As a last step we need configure the https endpoint to dynamically return certificates.

```elixir
config :myapp, MyappWeb.Endpoint,
  http: [port: 6000],
  https: [
    cipher_suite: :strong,
    port: 6001,
    sni_fun: &Myapp.CertbotClient.sni_fun/1 #Set the sni_fun
  ],
```

This tells cowboy to call `sni_fun/1` with the hostname of the request. This
function will ask the certificate provider for a certificate. The certificate provider
will return one, or first request one from Letsencrypt and then return it.

## FAQ
Is this tested in production?
 - No, be careful

Can I test this against a non-production acme server
 - Yes, you need to set the `:server` to `https://acme-staging.api.letsencrypt.org/`

Does it do certificate renewal?
 - Not yet, should not be really hard to do. Every now and then a sweep of the 
 certificate store to check for certificates that are about to expire, and renew
 a certificate for them.

How can I test this locally?
 - You need to make sure port 80 is available for the Acme server to request with
 the token verification call. You'll need to map port 80 to the https port you
 configured your endpoint to.

Are multiple account keys supported?
 - No, not yet. But willing to accept PR's.

How are multiple concurrent requests handled with certification requests?
 - Nothing is done, ideally some kind of lock is placed so requests after the first
 one will wait till a certificate is retrieved and then use this certificate. Nothing of the kind is done.

What happens if I request too many certificates?
 - You'll be ratelimited by Letsencrypt

I am debugging but don't see errors appearing?
 - Because everything happens as a result of calling the `sni_fun/1` callback,
 this is at such a level that many errors don't seem to appear.

What version of the Acme protocol is used?
 - Acme V1 is used, many thanks to this package: https://github.com/sikanhe/acme

Are alternative challenge methods (`dns-01`, `tls-sni-01`,`tls-alpn-01`)?
 - No, `tls-alpn-01` is currently not supported by the Acme client but would be interesting
 as it would make it unnecessary te expose port 80. `tls-sni-01` is not secure and
 `dns-01` is out of scope as of now. 


### Errors
```[error] %Certbot.Error{detail: "JWS has invalid anti-replay nonce twT0up7DWSrbe163DiRuKnPwd4ZpyXVER0p-COl1vAA", status: 400, type: "urn:acme:error:badNonce"}```
 - This is not handled yet, the nonce should be refreshed and then the request repeated.

```[error] Certbot.Acme.Client Certbot.Acme.Client received unexpected message in handle_info/2: {:ssl_closed, {:sslsocket, {:gen_tcp, #Port<0.76>, :tls_connection, :undefined}, [#PID<0.851.0>, #PID<0.850.0>]}}```
 - Don't know why this happens...

## Documentation
Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/certbot](https://hexdocs.pm/certbot).

