require 'test_helper'

class SalespeopleControllerTest < ActionController::TestCase
  setup do
    @salesperson = salespeople(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:salespeople)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create salesperson" do
    assert_difference('Salesperson.count') do
      post :create, salesperson: { age: @salesperson.age, gender: @salesperson.gender, height: @salesperson.height, name: @salesperson.name, weight: @salesperson.weight }
    end

    assert_redirected_to salesperson_path(assigns(:salesperson))
  end

  test "should show salesperson" do
    get :show, id: @salesperson
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @salesperson
    assert_response :success
  end

  test "should update salesperson" do
    patch :update, id: @salesperson, salesperson: { age: @salesperson.age, gender: @salesperson.gender, height: @salesperson.height, name: @salesperson.name, weight: @salesperson.weight }
    assert_redirected_to salesperson_path(assigns(:salesperson))
  end

  test "should destroy salesperson" do
    assert_difference('Salesperson.count', -1) do
      delete :destroy, id: @salesperson
    end

    assert_redirected_to salespeople_path
  end
end
