defmodule EventStreamDemo.CryptoBroadway do
  use GenServer
  require Logger
  alias Jason

  @crypto_list ["bitcoin", "ethereum", "ripple", "dogecoin", "cardano", "solana"]
  @api_url "https://api.coingecko.com/api/v3/simple/price?ids=#{Enum.join(@crypto_list, ",")}&vs_currencies=usd"
  @polling_interval 10_000  # Actualiza cada 10 segundos
  @topic "crypto_prices"  # Nombre del tópico en Kafka

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def init(state) do
    Logger.info("🚀 Iniciando CryptoBroadway...")
    schedule_fetch()
    {:ok, state}
  end

  def handle_info(:fetch_prices, state) do
    Logger.info("🔄 Ejecutando fetch de precios...")

    case fetch_crypto_prices() do
      {:ok, prices} ->
        Logger.info("📊 Precios obtenidos: #{inspect(prices)}")
        send_to_kafka(prices)
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
      {:ok, %{status: 200, body: body}} when is_map(body) ->
        {:ok, body}

      {:ok, %{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, parsed} -> {:ok, parsed}
          {:error, reason} -> {:error, "Error al decodificar JSON: #{inspect(reason)}"}
        end

      error ->
        {:error, error}
    end
  end

  defp send_to_kafka(prices) do
    encoded_message = Jason.encode!(prices)

    case KafkaEx.produce(@topic, 0, encoded_message) do
      :ok ->
        Logger.info("✅ Mensaje publicado en Kafka: #{inspect(prices)}")
      {:error, reason} ->
        Logger.error("❌ Error enviando mensaje a Kafka: #{inspect(reason)}")
    end
  end
end
