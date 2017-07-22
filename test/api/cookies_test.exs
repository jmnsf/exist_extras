defmodule ExistExtras.Api.CookiesTest do
  use ExUnit.Case, async: true

  alias ExistExtras.Api.Cookies

  describe "put_signed/4" do
    test "sets the given key in the connection's request cookies, expiring at end of session" do
      conn = %Plug.Conn{}
        |> Cookies.put_signed("a-key", "a-value")

      assert conn.resp_cookies
      assert conn.resp_cookies["a-key"]
      assert conn.resp_cookies["a-key"][:max_age] == 0
    end

    test "sets the value in base64" do
      conn = %Plug.Conn{}
        |> Cookies.put_signed("a-key", "a-value")

      {:ok, _} = Base.decode64 conn.resp_cookies["a-key"][:value]
    end

    test "appends a signature of the value" do
      conn = %Plug.Conn{}
        |> Cookies.put_signed("a-key", "a-value")

      [value | sig] =
        Base.decode64!(conn.resp_cookies["a-key"][:value])
        |> String.split("|")

      assert value == "a-value"
      assert sig
    end

    test "accepts a custom `max_age`" do
      conn = %Plug.Conn{}
        |> Cookies.put_signed("a-key", "a-value", 2000)

      assert conn.resp_cookies["a-key"][:max_age] == 2000
    end
  end

  describe "get_signed/2" do
    test "returns nil when no cookie exists for the key" do
      assert Cookies.get_signed(%Plug.Conn{req_cookies: %{}}, "key") == nil
    end

    test "returns the value at the key" do
      conn = Cookies.put_signed(%Plug.Conn{}, "a-key", "a-value")
      conn = struct(conn, req_cookies: %{"a-key" => conn.resp_cookies["a-key"][:value]})

      assert Cookies.get_signed(conn, "a-key") == "a-value"
    end

    test "returns nil if the value is not base64 encoded" do
      conn = %Plug.Conn{req_cookies: %{"a-key" => "a-value"}}
      assert Cookies.get_signed(conn, "a-key") == nil
    end

    test "returns nil if there is no signature" do
      conn = %Plug.Conn{req_cookies: %{"a-key" => Base.encode64("a-value")}}
      assert Cookies.get_signed(conn, "a-key") == nil
    end

    test "returns nil if signature does not match" do
      conn = %Plug.Conn{req_cookies: %{"a-key" => Base.encode64("a-value|bad-sig")}}
      assert Cookies.get_signed(conn, "a-key") == nil
    end
  end
end
