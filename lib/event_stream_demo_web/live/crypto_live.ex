defmodule EventStreamDemoWeb.CryptoLive do
  use EventStreamDemoWeb, :live_view
  require Logger

  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(EventStreamDemo.PubSub, "crypto_prices")
    {:ok, assign(socket, prices: %{}, last_updated: nil)}
  end

  def handle_info(prices, socket) do
    Logger.info("📥 Datos recibidos en CryptoLive: #{inspect(prices)}")

    case decode_prices(prices) do
      {:ok, decoded_prices} ->
        case validate_and_parse(decoded_prices) do
          {:ok, valid_prices} ->
            Logger.info("✅ Datos válidos, actualizando UI...")
            {:noreply, assign(socket, prices: valid_prices, last_updated: DateTime.utc_now())}

          {:error, reason} ->
            Logger.warning("⚠️ Datos inválidos tras validación: #{inspect(decoded_prices)} | Motivo: #{reason}")
            {:noreply, socket}
        end

      {:error, reason} ->
        Logger.warning("❌ Error al decodificar JSON: #{inspect(prices)} | Motivo: #{reason}")
        {:noreply, socket}
    end
  end

  defp validate_and_parse(prices) when is_map(prices) do
    if Enum.all?(prices, fn {_, v} -> is_map(v) and Map.has_key?(v, "usd") end) do
      {:ok, prices}
    else
      {:error, "Formato incorrecto de datos"}
    end
  end

  defp validate_and_parse(_), do: {:error, "Datos no son un mapa válido"}

  defp decode_prices(prices) when is_binary(prices) do
    case Jason.decode(prices) do
      {:ok, decoded} -> {:ok, decoded}
      {:error, reason} -> {:error, "Error al decodificar JSON: #{inspect(reason)}"}
    end
  end

  defp decode_prices(prices) when is_map(prices), do: {:ok, prices}
  defp decode_prices(_), do: {:error, "Formato desconocido"}

  def render(assigns) do
    ~H"""
    <div style="font-family: Arial, sans-serif; text-align: center;">
      <h2>📊 Precios de Criptomonedas en Tiempo Real</h2>

      <ul>
        <%= if map_size(@prices) > 0 do %>
          <%= for {coin, data} <- @prices do %>
            <li><strong><%= String.capitalize(coin) %>:</strong> $<%= data["usd"] || "N/A" %></li>
          <% end %>
        <% else %>
          <li><em>⏳ Cargando precios...</em></li>
        <% end %>
      </ul>

      <p><small>Última actualización:
        <%= case @last_updated do %>
          <% nil -> %>
            ⏳ Esperando datos...
          <% datetime -> %>
            <%= case Timex.format(datetime, "{h12}:{m} {AM}") do %>
              <% {:ok, formatted_time} -> %>
                <%= formatted_time %>
              <% _ -> %>
                ❌ Error formateando hora
            <% end %>
        <% end %>
      </small></p>
    </div>
    """
  end
end
