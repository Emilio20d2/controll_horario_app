require "test_helper"

class FichajesControllerTest < ActionDispatch::IntegrationTest
  test "should get semanal" do
    get fichajes_semanal_url
    assert_response :success
  end
end
