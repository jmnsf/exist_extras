defmodule ExistExtras.Google do

  # Find nutrition data sources:
  # GET https://www.googleapis.com/fitness/v1/users/me/dataSources?dataTypeName=com.google.nutrition
  #
  #
  # Get nutrition data for datasource:
  #
  #
  # fitness API
  # GET https://www.googleapis.com/fitness/v1/users/me/dataSources/raw%3Acom.google.nutrition%3Acom.myfitnesspal.android%3A/datasets/1500508800000000000-1501411879842000000?limit=1&key={YOUR_API_KEY}
  # https://developers.google.com/apis-explorer/?hl=en_US#p/fitness/v1/fitness.users.dataSources.datasets.get?userId=me&dataSourceId=raw%253Acom.google.nutrition%253Acom.myfitnesspal.android%253A&datasetId=1500508800000000000-1501411879842000000&limit=5&_h=11&
end
