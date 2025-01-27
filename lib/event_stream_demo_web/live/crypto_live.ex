defmodule EventStreamDemoWeb.CryptoLive do
  use EventStreamDemoWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(EventStreamDemo.PubSub, "crypto_prices")
    {:ok, assign(socket, prices: %{}, last_updated: nil)}
  end

  def handle_info(prices, socket) do
    {:noreply, assign(socket, prices: prices, last_updated: DateTime.utc_now())}
  end

  def render(assigns) do
    ~H"""
    <div style="font-family: Arial, sans-serif; text-align: center;">
      <h2>📊 Precios de Criptomonedas en Tiempo Real</h2>

      <ul>
        <%= for {coin, data} <- @prices do %>
        <li><strong><%= String.capitalize(coin) %>:</strong> $<%= data["usd"] || "Cargando..." %></li>
        <% end %>
      </ul>

      <p><small>Última actualización: <%= if @last_updated, do: @last_updated, else: "Esperando datos..." %></small></p>
    </div>
    """
  end
end
