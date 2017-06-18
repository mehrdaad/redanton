defmodule Danton.Club do
  use Danton.Web, :model

  schema "clubs" do
    field :name, :string
    field :description, :string
    has_many :channels, Danton.Channel

    timestamps()
  end

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name, :description])
    |> validate_required([:name, :description])
  end
end
