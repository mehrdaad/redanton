defmodule Danton.Api.V1.MessageController do
  use Danton.Web, :controller

  alias Danton.CheckIn
  alias Danton.Message
  alias Danton.Room

  # ===========================
  # ACTIONS
  # ===========================

  def index(conn, %{"post_id" => post_id}, current_user, _claims) do
    [room] = Repo.all(from(r in Room, where: r.post_id == ^post_id, preload: :post))
    messages = Ecto.assoc(room, :messages) |> Repo.all

    CheckIn.check_in_room(room, current_user)

    render(conn, "index.json", messages: messages)
  end

  def create(conn, %{"message" => message_params}, _current_user, _claims) do
    changeset = Message.changeset(%Message{}, message_params)

    case Repo.insert(changeset) do
      {:ok, message} ->
        conn
        |> put_status(:created)
        |> put_resp_header("location", message_path(conn, :show, message))
        |> render(conn, "show.json", message: message)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Danton.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}, _current_user, _claims) do
    message = Repo.get!(Message, id)
    render(conn, "show.html", message: message)
  end

  def update(conn, %{"id" => id, "message" => message_params}, _current_user, _claims) do
    message = Repo.get!(Message, id)
    changeset = Message.changeset(message, message_params)

    case Repo.update(changeset) do
      {:ok, _post} ->
        render(conn, "show.json", message: message)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Danton.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, _current_user, _claims) do
    message = Repo.get!(Message, id)
    Repo.delete!(message)
    send_resp(conn, :no_content, "")
  end
end
