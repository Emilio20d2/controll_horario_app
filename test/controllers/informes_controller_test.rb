require "test_helper"

class InformesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get informes_index_url
    assert_response :success
  end

  test "should get general_bolsas" do
    get informes_general_bolsas_url
    assert_response :success
  end
end
