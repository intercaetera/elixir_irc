defmodule ElixirIrcWeb.RootLive do
  import ElixirIrcWeb.CoreComponents
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    if connected?(socket), do:
      Phoenix.PubSub.subscribe(ElixirIrc.PubSub, "chat")

    socket =
      socket
      |> assign(username: "", message: "")
      |> stream(:chat, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-screen flex flex-col justify-end p-2">
      <ul class="p-2" id="chat" phx-update="stream">
        <li :for={{dom_id, message} <- @streams.chat} id={dom_id}>
          <pre class="h-4">
            <strong><%= message.username %></strong>: <span><%= message.message %></span>
          </pre>
        </li>
      </ul>
      <form
        class="w-full flex gap-4"
        autocomplete="off"
        phx-submit="send_message"
        phx-change="validate"
      >
        <div>
          <.input name="username" label="Username" value={@username} />
        </div>
        <div class="w-full">
          <.input label="Message" name="message" value={@message} />
        </div>
        <.button class="h-10 self-end">Send</.button>
      </form>
      <div class="text-xs text-right pt-2">Running on <%= inspect(self()) %></div>
    </div>
    """
  end

  def handle_event("validate", %{"username" => username, "message" => message}, socket) do
    socket = assign(socket, username: username, message: message)
    {:noreply, socket}
  end

  def handle_event("send_message", %{"username" => username, "message" => message}, socket) do
    data = %{
      id: inspect(:erlang.unique_integer()),
      username: username,
      message: message
    }

    Phoenix.PubSub.broadcast(ElixirIrc.PubSub, "chat", {:send_message, data})

    socket = assign(socket, message: "")

    {:noreply, socket}
  end

  def handle_info({:send_message, data}, socket) do
    socket = stream_insert(socket, :chat, data)
    {:noreply, socket}
  end
end
