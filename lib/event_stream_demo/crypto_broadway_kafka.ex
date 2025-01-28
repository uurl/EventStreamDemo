defmodule EventStreamDemo.CryptoBroadwayKafka do
  use Broadway
  alias Broadway.Message
  require Logger

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {
          BroadwayKafka.Producer,
          hosts: [localhost: 9092],
          #hosts: [{"localhost", 9092}],
          group_id: "crypto_group",
          topics: ["crypto_prices"]
        },
        concurrency: 1
      ],
      processors: [
        default: [concurrency: 2]
      ]
    )
  end

  def handle_message(_processor, %Message{data: data} = message, _context) do
    IO.inspect(data, label: "Received message")

    case Jason.decode(data) do
      {:ok, prices} ->
        Phoenix.PubSub.broadcast(EventStreamDemo.PubSub, "crypto_prices", prices)
        Logger.info("📥 Datos consumidos desde Kafka: #{inspect(prices)}")
        message
      {:error, reason} ->
        Logger.warning("⚠️ No se pudo decodificar JSON: #{inspect(reason)} | Datos: #{inspect(data)}")
        Message.failed(message, reason)  # Marcar el mensaje como fallido
    end
  end

end
