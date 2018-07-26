defmodule PareOfSlacks do
  defmodule API do
    use Tesla

    @api_key Application.get_env(:pare_of_slacks, :api_key)

    plug Tesla.Middleware.BaseUrl, "https://slack.com/api"
    plug Tesla.Middleware.Headers, [{"Authorization", "Bearer #{@api_key}"}]
    plug Tesla.Middleware.JSON


    def files_list(params \\ []) do
      get("files.list", query: params)
    end

    def files_info(params) do
      get("files.info", query: params)
    end

    def files_delete(params) do
      post("files.delete", params)
    end
  end

  def all_files do
    fetch_files_from_page(1)
  end

  def delete_older_than(offset) do
    files_older_than(offset)
    # |> Enum.take(10)
    |> Enum.each(fn file ->
      case API.files_delete(%{file: file["id"]}) do
        {:ok, %Tesla.Env{body: %{"ok" => true}}} ->
          IO.puts "Deleted #{file["id"]}"
        other ->
          IO.inspect other
      end
    end)
  end

  # offset, e.g. months: 1, days: 3
  def files_older_than(offset) do
    min = unix_at(offset)
    all_files()
    |> Enum.filter(fn file ->
      file["timestamp"] < min
    end)
  end

  defp unix_at(offset) do
    DateTime.utc_now()
    |> Timex.shift(Keyword.new(offset, fn {k, v} -> {k, -v} end))
    |> Timex.to_unix()
  end

  defp fetch_files_from_page(page, acc \\ []) do
    {:ok, %Tesla.Env{body: body}} = API.files_list(page: page)

    files = acc ++ body["files"]
    cond do
      page < body["paging"]["pages"] ->
        fetch_files_from_page(page + 1, files)
      true ->
        files
    end
  end
end
