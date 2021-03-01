defmodule Rocketpay.Accounts.Transaction do
  alias Ecto.Multi

  alias Rocketpay.Repo
  alias Rocketpay.Accounts.Operation
  alias Rocketpay.Accounts.Transactions.Response, as: TransactionsResponse

  def call(%{"from" => from_id, "to" => to_id, "value" => value}) do
    withdraw_params = build_params(from_id, value)
    deposit_params = build_params(to_id, value)

    Multi.new()
    |> Multi.merge(fn _changes -> Operation.call(withdraw_params, :withdraw) end)
    |> Multi.merge(fn _changes -> Operation.call(deposit_params, :deposit) end)
    |> run_transaction()
  end

  defp build_params(id, value), do: %{"id" => id, "value" => value}

  defp run_transaction(multi) do
    case Repo.transaction(multi) do
      {:ok, %{withdraw: from_account, deposit: to_account}} ->
        {:ok, TransactionsResponse.build(from_account, to_account)}
      {:error, _operation, reason, _changes} -> {:error, reason}
    end
  end


end