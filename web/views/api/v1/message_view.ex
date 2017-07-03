defmodule Danton.Api.V1.MessageView do
  use Danton.Web, :view

  def render("index.json", %{messages: messages}) do
    %{data: render_many(messages, Danton.Api.V1.MessageView, "message.json")}
  end

  def render("show.json", %{message: message}) do
    %{data: render_one(message, Danton.Api.V1.MessageView, "message.json")}
  end

  def render("message.json", %{message: message}) do
    %{
      id: message.id,
      body: message.body,
      room_id: message.room,
      user_id: message.user
    }
  end
end