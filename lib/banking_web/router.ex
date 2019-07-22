defmodule BankingWeb.Router do
  use BankingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :authenticated do
    plug Banking.Auth.Pipeline
  end

  scope "/api", BankingWeb do
    pipe_through :api
    
    # Unauthenticated routes
    scope "/v1", V1, as: :v1 do
      post "/signin", AuthController, :signin
      post "/signup", AccountController, :create
    end
    
    # Authenticated routes
    scope "/v1", V1, as: :v1 do
      pipe_through [:authenticated]

      get "/accounts", AccountController, :index
    end
  end
end
