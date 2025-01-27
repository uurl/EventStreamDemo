defmodule EventStreamDemo.CryptoBroadway do
  use GenServer
  require Logger

  @crypto_list ["bitcoin", "ethereum", "ripple", "dogecoin", "cardano", "solana"]
  @api_url "https://api.coingecko.com/api/v3/simple/price?ids=#{Enum.join(@crypto_list, ",")}&vs_currencies=usd"
  @polling_interval 10_000  # 🔹 Actualiza cada 5 segundos

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    schedule_fetch()
    {:ok, state}
  end

  def handle_info(:fetch_prices, state) do
    case fetch_crypto_prices() do
      {:ok, prices} ->
        Phoenix.PubSub.broadcast(EventStreamDemo.PubSub, "crypto_prices", prices)
        Logger.info("📈 Datos actualizados: #{inspect(prices)}")

      {:error, reason} ->
        Logger.error("❌ Error obteniendo datos: #{inspect(reason)}")
    end

    schedule_fetch()
    {:noreply, state}
  end

  defp schedule_fetch do
    Process.send_after(self(), :fetch_prices, @polling_interval)
  end

  defp fetch_crypto_prices do
    case Req.get(@api_url) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      error -> {:error, error}
    end
  end
end
