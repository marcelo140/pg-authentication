defmodule AuthRouter do
  use Plug.Router

  plug :put_secret_key_base

  plug Plug.Session,
    store: :cookie,
    key: "_notetaker_key",
    signing_salt: Application.get_env(:auth, :signing_salt)

  plug :match

  plug :fetch_session

  plug AuthAuthenticator

  plug AuthAuthorizator

  plug :dispatch

  get "/" do
    name = case conn.assigns[:user] do
      nil -> "?? Wait, who the heck are you?"
      name -> name
    end

    conn |> send_resp(200, "Hello #{name}")
  end

  post "/login/:name" do
    session_id = AuthSession.create_session(name)    

    conn 
    |> put_session("id", session_id)
    |> redirect_to("/")
  end

  post "/logout/" do
    conn 
    |> get_session("id")
    |> AuthSession.destroy_session()

    conn |> clear_session |> redirect_to("/")
  end

  get "/jwt/:name" do
    conn 
    |> put_resp_cookie("jwt", AuthJWT.generate_jwt(name))
    |> redirect_to("/")
  end

  get "/admin", private: %{authenticate: true} do
    send_resp(conn, 200, "Welcome home")
  end

  match _ do
    send_resp(conn, 404, "Page not found!")
  end

  defp put_secret_key_base(conn, _) do
    put_in conn.secret_key_base, Application.get_env(:auth, :secret_key_base)
  end

  defp redirect_to(conn, path) do
    conn
    |> put_resp_header("location", path)
    |> send_resp(301, "")
  end
end
