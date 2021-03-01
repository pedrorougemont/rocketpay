defmodule Rocketpay.Accounts.Operation do

  alias Ecto.Multi

  alias Rocketpay.Account

  def call(%{"id" => id, "value" => value}, operation) do
    account_ref = account_reference(operation)

    Multi.new()
    |> Multi.run(account_ref, fn repo, _changes ->
      get_account(repo, id)
    end)
    |> Multi.run(operation, fn repo, changes ->
      account = Map.get(changes, account_ref)
      update_balance(repo, account, value, operation)
    end)
  end

  defp account_reference(operation) do
    "account_#{Atom.to_string(operation)}"
    |> String.to_atom()
  end

  defp get_account(repo, id) do
    case repo.get(Account, id) do
      nil -> {:error, "Account not found!"}
      account -> {:ok, account}
    end
  end

  defp update_balance(repo, account, value, operation) do
    account
    |> sum_values(value, operation)
    |> update_account(repo, account)
  end

  defp sum_values(%Account{balance: balance}, value, operation) do
    value
    |> Decimal.cast()
    |> handle_cast(balance, operation)
  end

  defp handle_cast({:ok, value}, balance, :deposit), do: Decimal.add(balance, value)
  defp handle_cast({:ok, value}, balance, :withdraw), do: Decimal.sub(balance, value)
  defp handle_cast(:error, _balance, _operation), do: {:error, "Invalid value for the operation."}

  defp update_account({:error, _reason} = error, _repo, _account), do: error
  defp update_account(new_balance, repo, account) do
    account
    |> Account.changeset(%{balance: new_balance})
    |> repo.update()
  end

end
