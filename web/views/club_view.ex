defmodule Danton.ClubView do
  use Danton.Web, :view

  def user_is_admin(user, club_id) do
    Membership.user_is_admin(user, club_id)
  end

  def post_count_string(club) do
    case club.post_count do
      1 -> Integer.to_string(club.post_count) <> " post"
      _ -> Integer.to_string(club.post_count) <> " posts"
    end
  end
end
