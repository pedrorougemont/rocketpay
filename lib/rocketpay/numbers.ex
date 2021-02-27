defmodule Rocketpay.Numbers do
  def sum_from_file(filename) do
    "#{filename}.csv"
    |> File.read()
    |> handle_file()
  end

  defp handle_file({:ok, file_contents}) do
    {:ok, %{result:
      file_contents
      |> String.split(",")
      |> Stream.map(fn number -> String.to_integer(number) end)
      |> Enum.sum()
    }}
  end
  defp handle_file({:error, _reason}), do: {:error, %{message: "Invalid filename."}}
end
