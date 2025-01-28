defmodule EventStreamDemo.CryptoProducer do
  require Logger
  alias Jason

  @crypto_list ["bitcoin", "ethereum", "ripple", "dogecoin", "cardano", "solana"]
  @api_url "https://api.coingecko.com/api/v3/simple/price?ids=#{Enum.join(@crypto_list, ",")}&vs_currencies=usd"
  @topic "crypto_prices"
  @kafka_worker :crypto_client
  @brokers [{"localhost", 9092}]

  def publish_prices do
    start_kafka_client()  # Asegurar que el cliente Kafka esté activo

    case fetch_crypto_prices() do
      {:ok, prices} ->
        Logger.info("✅ Datos obtenidos: #{inspect(prices)}")
        send_to_kafka(prices)

      {:error, reason} ->
        Logger.error("❌ Error obteniendo datos: #{inspect(reason)}")
    end
  end

  defp start_kafka_client do
    case KafkaEx.create_worker(@kafka_worker, [uris: @brokers]) do
      :ok ->
        Logger.info("✅ Cliente KafkaEx iniciado correctamente.")
        :ok

      {:ok, _pid} ->  # <-- Maneja esta respuesta correctamente
        Logger.info("✅ Cliente KafkaEx ya estaba corriendo.")
        :ok

      {:error, {:already_started, _}} ->
        Logger.info("✅ Cliente KafkaEx ya estaba corriendo.")
        :ok

      {:error, reason} ->
        Logger.error("❌ Error iniciando KafkaEx client: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def fetch_crypto_prices do
    case Req.get(@api_url) do
      {:ok, %{status: 200, body: body}} -> {:ok, body}
      error -> {:error, error}
    end
  end

  def send_to_kafka(prices) do
    encoded_message = Jason.encode!(prices)

    case KafkaEx.produce(@topic, 0, encoded_message) do
      :ok ->
        Logger.info("✅ Mensaje enviado a Kafka correctamente: #{encoded_message}")

      {:error, reason} ->
        Logger.error("❌ Error enviando mensaje a Kafka: #{inspect(reason)}")
    end
  end
end
