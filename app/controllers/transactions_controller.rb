class TransactionsController < ApplicationController
  before_action :set_transaction_log, only: [:show, :edit, :update, :destroy]

  # GET /transaction_logs
  # GET /transaction_logs.json
  def index
    @transaction_logs = Transaction.all
  end

  # GET /transaction_logs/1
  # GET /transaction_logs/1.json
  def show
  end

  # GET /transaction_logs/new
  def new
    @transaction_log = Transaction.new
  end

  # GET /transaction_logs/1/edit
  def edit
  end

  # POST /transaction_logs
  # POST /transaction_logs.json
  def create
    @transaction_log = Transaction.new(transaction_log_params)

    # @transaction_log.tap{|t| t.tran_type.to_i }

    respond_to do |format|
      if @transaction_log.save
        format.html { redirect_to @transaction_log, notice: 'Transaction log was successfully created.' }
        format.json { render :show, status: :created, location: @transaction_log }
      else
        format.html { render :new }
        format.json { render json: @transaction_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /transaction_logs/1
  # PATCH/PUT /transaction_logs/1.json
  def update
    respond_to do |format|
      if @transaction_log.update(transaction_log_params)
        format.html { redirect_to @transaction, notice: 'Transaction log was successfully updated.' }
        format.json { render :show, status: :ok, location: @transaction_log }
      else
        format.html { render :edit }
        format.json { render json: @transaction_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /transaction_logs/1
  # DELETE /transaction_logs/1.json
  def destroy
    @transaction_log.destroy
    respond_to do |format|
      format.html { redirect_to transactions_url, notice: 'Transaction log was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_transaction_log
      @transaction_log = Transaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def transaction_log_params
      params.require(:transaction).permit(:tran_type, :amount, :account_id, :salesperson_id)
    end
end
