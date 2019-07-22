defmodule BankingWeb.V1.AccountView do
  use BankingWeb, :view

  alias BankingWeb.V1.AccountView

  def render("index.json", %{accounts: accounts}) do
    render_many(accounts, AccountView, "account.json")
  end

  def render("show.json", %{account: account}) do
    render_one(account, AccountView, "account.json")
  end

  def render("account.json", %{account: account}) do
    %{id: account.id, name: account.name}
  end
end
