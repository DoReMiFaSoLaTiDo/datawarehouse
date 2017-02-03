require 'test_helper'

class TransactionLogsControllerTest < ActionController::TestCase
  setup do
    @transaction_log = transaction_logs(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:transactions)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create transaction_log" do
    assert_difference('TransactionLog.count') do
      post :create, transaction_log: {account_id: @transaction_log.account_id, amount: @transaction_log.amount, salesperson_id: @transaction.salesperson_id, tran_type: @transaction.tran_type }
    end

    assert_redirected_to transaction_path(assigns(:transaction_log))
  end

  test "should show transaction_log" do
    get :show, id: @transaction_log
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @transaction_log
    assert_response :success
  end

  test "should update transaction_log" do
    patch :update, id: @transaction_log, transaction_log: {account_id: @transaction.account_id, amount: @transaction_log.amount, salesperson_id: @transaction_log.salesperson_id, tran_type: @transaction.tran_type }
    assert_redirected_to transaction_path(assigns(:transaction_log))
  end

  test "should destroy transaction_log" do
    assert_difference('TransactionLog.count', -1) do
      delete :destroy, id: @transaction_log
    end

    assert_redirected_to transactions_path
  end
end
