defmodule Danton.PostView do
  use Danton.Web, :view

  # def render_stream(posts) do
  #   render(Danton.PostView, "stream.html", posts: posts)
  # end

  def user_can_edit(post, current_user) do
    post.user_id == current_user.id
  end

  # helpers for stream
  def parse_link(post, parent_type, parent) do
    if (post.url && String.length(post.url) > 0) do
      has_scheme = String.contains? post.url, "http"
      if (has_scheme) do
        post.url
      else
        "http://#{post.url}"
      end
    else

      parent_post_path(post, parent_type, parent)
    end
  end

  def parent_post_path(post, parent_type, parent) do
    case (parent_type) do
      :club -> "/clubs/" <> Integer.to_string(parent.id) <> "/posts/" <> Integer.to_string(post.id)
      :channel -> "/channels/" <> Integer.to_string(parent.id) <> "/posts/" <> Integer.to_string(post.id)
      :none -> "posts/" <> Integer.to_string(post.id)
    end
  end

  # helpers for show
  def msg_class(message, current_user_id) do
    if (message.user_id == current_user_id) do
      "message-current-user"
    else
      "message-other-user"
    end
  end

  def posted_text(post) do
    post.user && post.user.name <> " posted to "
  end

  def discussion_link_text(post) do
    case count = Message.count_for_post(post) do
      0 -> "Discuss"
      1 -> "Discuss (1 comment)"
      _ -> "Discuss ("<> Integer.to_string(count) <>" comments)"
    end
  end

  def latest_activity_text(post) do
    time = Post.latest_activity_time(post)
    activity_type = Post.latest_activity_type(post)
    if activity_type == :post do
      "Posted " <> Timex.from_now(time)
    else
      msg = Message.latest_for_post(post) |> Danton.Repo.preload(:user)
      "Message from " <> msg.user.name <> " " <> Timex.from_now(time)
    end
  end

  # helpers for form
  def dropdown_text(channel, clubs) do
    club = Enum.find(clubs, &(&1.id == channel.club_id))
    channel.name <> " (" <> club.name <> ")"
  end
end
