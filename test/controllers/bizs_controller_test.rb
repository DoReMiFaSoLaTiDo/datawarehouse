require 'test_helper'

class BizsControllerTest < ActionController::TestCase
  setup do
    @biz = bizs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:'bizs.js')
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create biz" do
    assert_difference('Biz.count') do
      post :create, biz: { dimension: @biz.dimension, fact: @biz.fact }
    end

    assert_redirected_to biz_path(assigns(:biz))
  end

  test "should show biz" do
    get :show, id: @biz
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @biz
    assert_response :success
  end

  test "should update biz" do
    patch :update, id: @biz, biz: { dimension: @biz.dimension, fact: @biz.fact }
    assert_redirected_to biz_path(assigns(:biz))
  end

  test "should destroy biz" do
    assert_difference('Biz.count', -1) do
      delete :destroy, id: @biz
    end

    assert_redirected_to bizs_path
  end
end
