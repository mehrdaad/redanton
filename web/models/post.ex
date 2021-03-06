defmodule Danton.Post do
  use Danton.Web, :model

  # ===========================
  # ECTO CONFIG
  # ===========================

  schema "posts" do
    field :title, :string
    field :description, :string
    field :type, :string
    field :url, :string
    field :activity_at, Ecto.DateTime

    belongs_to :club, Club
    belongs_to :channel, Channel
    belongs_to :user, User
    has_one :room, Room
    has_many :posts_tags, PostsTags
    many_to_many :messages, Message, join_through: "room"
    many_to_many :tags, Tag, join_through: "posts_tags"

    field :tag_names, :string, virtual: true

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :description, :type, :url, :activity_at])
    |> validate_required([:title])
    |> validate_length(:title, min: 1, max: 150)
  end

  # ===========================
  # QUERIES
  # ===========================

  @doc """
  gets all the channels for a list of clubs
  """
  def for_channel_ids(query \\ Post, channel_ids) do
    from(p in query, where: p.channel_id in ^channel_ids)
  end

  def for_club_ids(query \\ Post, club_ids) do
    from(p in query, where: p.club_id in ^club_ids)
  end

  # TODO: do in one query
  def for_tag_id(tag_id) do
    tag = Repo.get(Tag, tag_id)
    Ecto.assoc(tag, :posts)
  end

  def for_channel_stream(channel_id) do
    for_channel_ids([channel_id]) |> with_stream_preloads()
  end

  def user_posts(user) do
    Club.ids_for_user(user)
    |> for_club_ids()
  end

  def for_clubs(clubs) do
    Enum.map(clubs, &(&1.id))
    |> for_club_ids()
  end

  def for_club(club) do
    [club.id]
    |> for_club_ids()
  end

  def for_front_page(user) do
    Club.ids_for_user(user)
    |> for_club_ids()
    |> by_activity()
  end

  def by_activity(query \\ Post) do
    query |> order_by(desc: :activity_at)
  end

  def most_recent(query \\ Post) do
    query |> by_activity() |> first()
  end

  def most_recent_for_channel(channel) do
    Ecto.assoc(channel, :posts) |> most_recent()
  end

  def most_recent_for_club(club) do
    Post.for_club(club) |> most_recent()
  end

  # does a full room load and does not need to
  def for_message(message) do
    message
    |> Ecto.assoc(:room)
    |> Repo.one()
    |> Ecto.assoc(:post)
  end

  def with_stream_preloads(list) do
    list
    |> Repo.preload(room: :messages)
    |> Repo.preload(:user)
    |> Repo.preload(:channel)
    |> Repo.preload(:club)
  end

  def with_messages(query \\ Post) do
    query
      |> join(:left, [p], _ in assoc(p, :room))
      |> join(:left, [_, room], _ in assoc(room, :messages))
      |> preload([_, r, m], [room: {r, messages: m}])
  end

  def user_has_none(user) do
    post_count = Post.for_front_page(user) |> Repo.aggregate(:count, :id)
    post_count == 0
  end

  def with_tag_names(post) do
    tag_names = Ecto.assoc(post, :tags)
      |> Repo.all()
      |> Enum.map(&(&1.name))
      |> Enum.join(",")

    %{post | tag_names: tag_names}
  end

  def with_posts_tags_and_tags(list) do
    list
    |> Repo.preload(:posts_tags)
    |> Repo.preload(:tags)
  end

  def with_real_post_counts(posts, club_ids) when is_list(posts) do
    Enum.map(posts, &(with_real_post_counts(&1, club_ids)))
  end

  def with_real_post_counts(post, club_ids) do
    new_tags = Tag.with_post_counts_for_club_ids(post.tags, club_ids)
    %{post | tags: new_tags}
  end

  # ===========================
  # CREATE
  # ===========================

  # TODO: REMOVE THIS ONCE CHAN => TAG is done
  # def create_for_channel_and_user(chan, user, post_params, msg_params \\ false) do
  #   post_cs = Post.changeset(%Post{
  #     user_id: user.id,
  #     channel_id: chan.id,
  #     club_id: chan.club_id
  #   }, %{
  #     title: post_params["title"],
  #     description: post_params["description"],
  #     type: post_params["type"],
  #     url: post_params["url"],
  #     activity_at: Ecto.DateTime.utc
  #   })

  #   multi = Multi.new
  #     |> Multi.insert(:post, post_cs)
  #     |> Multi.run(:room, fn %{post: post} ->
  #       room_cs = Ecto.build_assoc(post, :room, %{})
  #       Repo.insert(room_cs)
  #     end)
  #     |> Multi.run(:message, fn %{room: room} ->
  #       if (msg_params && msg_params.body) do
  #         msg_cs = Ecto.build_assoc(room, :messages, msg_params)
  #         Repo.insert(msg_cs)
  #       else
  #         {:ok, :no_message}
  #       end
  #     end)

  #   case Repo.transaction(multi) do
  #     {:ok, %{post: post, room: room} = res} ->
  #       Task.start(__MODULE__, :notify_new_post, [post, room, user])
  #       {:ok, res}
  #     _ ->
  #       {:error, post_cs}
  #   end
  # end

  def create_for_club_and_user(club, user, post_params, msg_params \\ false) do
    post_cs = Post.changeset(%Post{
      user_id: user.id,
      club_id: club.id
    }, %{
      title: post_params["title"],
      description: post_params["description"],
      type: post_params["type"],
      url: post_params["url"],
      activity_at: Ecto.DateTime.utc
    })

    tags_params = post_params["tags"] || ""

    multi = Multi.new
      |> Multi.insert(:post, post_cs)
      |> Multi.run(:room, fn %{post: post} ->
        room_cs = Ecto.build_assoc(post, :room, %{})
        Repo.insert(room_cs)
      end)
      |> Multi.run(:message, fn %{room: room} ->
        if (msg_params && msg_params.body) do
          msg_cs = Ecto.build_assoc(room, :messages, msg_params)
          Repo.insert(msg_cs)
        else
          {:ok, :no_message}
        end
      end)
      |> Multi.run(:tags, fn %{post: post} ->
        Tag.build_tags_from_params(post, tags_params)
      end)

    case Repo.transaction(multi) do
      {:ok, %{post: post, room: room} = res} ->
        Task.start(__MODULE__, :notify_new_post, [post, room, user])
        {:ok, res}
      _ ->
        {:error, post_cs}
    end
  end

  def update_from_params(post, params) do
    tags_params = params["tags"]
    post_cs = Post.changeset(post, params)

    multi = Multi.new
      |> Multi.update(:post, post_cs)
      |> Multi.run(:remove_tag_assocs, fn %{post: post} ->
        Ecto.assoc(post, :posts_tags) |> Repo.delete_all()
        {:ok, :done}
      end)
      |> Multi.run(:tags, fn %{post: post} ->
        Tag.build_tags_from_params(post, tags_params)
      end)

    case Repo.transaction(multi) do
      {:ok, %{post: post} = res} ->
        {:ok, post}
      e ->
        IO.puts "HEY MILE"
        IO.puts(inspect(e))
        {:error, post_cs}
    end
  end

  def notify_new_post(post, room, user) do
    users_for_room = Room.user_ids_for_room(room)
    users_to_send_to = users_for_room -- [user.id]

    Danton.Communication.notify_users(
      users_to_send_to,
      :new_post,
      %{
        poster_name: user.name || user.email,
        post_title: post.title,
        post_path: "/posts/#{post.id}"
      }
    )
  end

  # ===========================
  # DESTROY
  # ===========================

	@doc """
  Removes a post and all associated content
  """

  # TODO: put all of this in a transaction
	def destroy(post_id) do
    rooms = Repo.all(from(r in Room, where: r.post_id == ^post_id))
		Room.destroy_list(rooms)

    post = Repo.get(Post, post_id)

    Ecto.assoc(post, :posts_tags) |> Repo.delete_all()

		Repo.delete!(post)
  end

  @doc """
  Removes a list of posts and all associated content
  """
	def destroy_list(post_list) do
    post_list
      |> Enum.map(&(&1.id))
      |> Enum.each(&Post.destroy/1)
  end

  def load_messages(post) do
    post |> Repo.preload([room: :messages])
  end

  # ===========================
  # OTHER
  # ===========================

  def user_is_owner(post_id, user_id) do
    # can just select the user_id down the line
    post = Repo.get(Post, post_id)
    post.user_id ==user_id
  end

  def update_activity_for_message!(message) do
    post = Post.for_message(message) |> Repo.one()
    Post.changeset(post, %{activity_at: message.inserted_at}) |> Repo.update
  end

  def latest_activity_time(post) do
    message = Message.latest_for_post(post)
    message && message.inserted_at || post.inserted_at
  end

  def latest_activity_type(post) do
    if (Message.latest_for_post(post)) do
      :messages
    else
      :post
    end
  end
end
