defmodule ExistExtras.ExistTest do
  use ExUnit.Case, async: true

  alias ExistExtras.Exist

  describe "authorized?/1" do
    test "returns true if we have an Exist access_token for the given user_id" do
      Redix.command!(
        ExistExtras.Redis.redis_connection!(),
        ~w(SET exist:access_tokens:exist-test-1 1234567890)
      )

      assert Exist.authorized?("exist-test-1") == true
    end

    test "returns false if we do not have an Exist access_token for the given user_id" do
      assert Exist.authorized?("non-existant-id") == false
    end
  end
end

defmodule ExistExtras.ExistTestSync do
  use ExUnit.Case, async: false
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias ExistExtras.Exist

  setup_all do
    ExVCR.Config.cassette_library_dir "fixtures/vcr_cassettes/exist"
    Redix.command!(
      ExistExtras.Redis.redis_connection!(),
      ~w(SET exist:access_tokens:1234567890 123123)
    )
    :ok
  end

  describe "acquired_attributes/1" do
    test "returns the acquired attributes for the given user_id" do
      use_cassette "acquired_attributes" do
        attrs = Exist.acquired_attributes("1234567890")
        assert length(attrs) == 8
        assert Enum.map(attrs, fn %{"label" => label} -> label end) == [
          "Energy in",
          "Carbohydrates",
          "Fat",
          "Fibre",
          "Protein",
          "Sodium",
          "Sugar",
          "Cholesterol"
        ]
      end
    end
  end

  describe "acquire_attribute_ownership/1" do
    test "aquires ownership of all necessary nutrition attributes" do
      use_cassette "acquire_attribute_ownership", match_requests_on: [:request_body] do
        assert Exist.acquire_attribute_ownership("1234567890") == :ok
      end
    end
  end

  describe "save_nutrition/1" do
    test "uploads the given nutrition data to Exist for the given user_id and date" do
      use_cassette "save_nutrition", match_requests_on: [:request_body] do
        assert Exist.save_nutrition("1234567890", "2017-07-26", [
          {:energy, 10786.352},
          {:carbohydrates, 65.0},
          {:cholesterol, 138.0},
          {:fat, 179.0},
          {:fibre, 28.0},
          {:protein, 167.0},
          {:sodium, 1108.0},
          {:sugar, 24.0}
        ]) == :ok
      end
    end
  end
end
