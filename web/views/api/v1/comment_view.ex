defmodule Danton.Api.V1.CommentView do
  use Danton.Web, :view

  def render("index.json", %{comments: comments}) do
    %{data: render_many(comments, Danton.Api.V1.CommentView, "comment.json")}
  end

  def render("show.json", %{comment: comment}) do
    %{data: render_one(comment, Danton.Api.V1.CommentView, "comment.json")}
  end

  def render("comment.json", %{comment: comment}) do
    %{id: comment.id}
  end
end
