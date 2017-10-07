defmodule Danton.PostController do
  use Danton.Web, :controller

  plug Guardian.Plug.EnsureAuthenticated, handler: __MODULE__, typ: "access"

  # ===========================
  # ACTIONS
  # ===========================

  def index(conn,  %{"channel_id" => channel_id}, _current_user, _claims) do
    posts = Post.for_channel_stream(channel_id)
      |> Repo.all()
      |> Repo.preload(:user)
      |> Repo.preload(:channel)

    render(conn, "index.html", posts: posts, channel_id: channel_id)
  end

  def front_page(conn, _params, current_user, _claims) do
    posts = Post.for_front_page(current_user)
      |> Repo.all()
      |> Repo.preload(:user)
      |> Repo.preload(:channel)

    render(conn, "front_page.html", posts: posts)
  end

  def new(conn, %{"channel_id" => channel_id}, _current_user, _claims) do
    changeset = Post.changeset(%Post{})
    render(conn, "new.html", changeset: changeset, channel_id: channel_id, channels: :none)
  end

  def new(conn, _params, current_user, _claims) do
    changeset = Post.changeset(%Post{})
    channels = Channel.for_user(current_user) |> Repo.all()
    render(conn, "new.html", changeset: changeset, channel_id: :none, channels: channels)
  end

  def create(conn, %{"post" => post_params, "channel_id" => channel_id}, current_user, _claims) do
    channel = Repo.get(Channel, channel_id)

    # TODO: There must be a nicer way to do this
    post_struct = %Post{
      title: post_params["title"],
      description: post_params["description"],
      type: post_params["type"],
      url: post_params["url"],
    }

    case Channel.make_post_for_user(channel, current_user, post_struct) do
      {:ok, post} ->
        # TODO: find a better spot for this
        Post.make_room(post)

        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: channel_path(conn, :show, channel_id))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, channel_id: channel_id)
    end
  end

  def create(conn, %{"post" => post_params}, current_user, _claims) do
    channel_id = post_params["channel_id"]
    channel = Repo.get(Channel, channel_id)

    # TODO: There must be a nicer way to do this
    post_struct = %Post{
      title: post_params["title"],
      description: post_params["description"],
      type: post_params["type"],
      url: post_params["url"],
    }

    case Channel.make_post_for_user(channel, current_user, post_struct) do
      {:ok, post} ->
        # TODO: find a better spot for this
        Post.make_room(post)

        conn
        |> put_flash(:info, "Post created successfully.")
        |> redirect(to: channel_path(conn, :show, channel_id))
      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset, channel_id: channel_id)
    end
  end

  def show(conn, %{"id" => id}, current_user, _claims) do
    # TODO: make sure posts have rooms
    post = Repo.get!(Post, id)
      |> Repo.preload(:room)
      |> Post.load_messages()
      |> Repo.preload(:user)
      |> Repo.preload(:channel)

    # TODO: get the actual messages for the room
    messages = Message.for_post(post.id)
      |> Repo.all()
      |> Repo.preload(:user)

    render(
      conn,
      "show.html",
      post: post,
      room_id: post.room && post.room.id,
      messages: messages,
      user_id: current_user.id
    )
  end

  def chat(conn, %{"post_id" => post_id}, _current_user, _claims) do
    post = Repo.get!(Post, post_id)
    render(conn, "chat.html", post: post)
  end

  def edit(conn, %{"id" => id}, _current_user, _claims) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post)
    render(conn, "edit.html", post: post, changeset: changeset, channel_id: post.channel_id)
  end

  def update(conn, %{"id" => id, "post" => post_params}, _current_user, _claims) do
    post = Repo.get!(Post, id)
    changeset = Post.changeset(post, post_params)

    case Repo.update(changeset) do
      {:ok, post} ->
        conn
        |> put_flash(:info, "Post updated successfully.")
        |> redirect(to: post_path(conn, :show, post))
      {:error, changeset} ->
        render(conn, "edit.html", post: post, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}, _current_user, _claims) do
    post = Repo.get!(Post, id)
    channel_id = post.channel_id

    # Here we use delete! (with a bang) because we expect
    # it to always work (and if it does not, it will raise).
    Repo.delete!(post)

    conn
    |> put_flash(:info, "Post deleted successfully.")
    |> redirect(to: channel_post_path(conn, :index, channel_id))
  end
end
