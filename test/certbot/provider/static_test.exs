defmodule Certbot.Provider.StaticTest do
  use ExUnit.Case
  doctest Certbot.Provider.Static

  defmodule TestStatic do
    use Certbot.Provider.Static,
      certificates: %{
        "test.com" => Helper.build_certificate()
      }
  end

  test "returns certificate for known hostname" do
    assert %Certbot.Certificate{} = certificate = TestStatic.get_by_hostname("test.com")
    assert certificate == Helper.build_certificate()
  end

  test "returns nil for unknown hostname" do
    assert nil == TestStatic.get_by_hostname("bogus.com")
  end
end
