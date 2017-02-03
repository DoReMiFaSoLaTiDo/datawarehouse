class Transaction < ActiveRecord::Base
  enum tran_type: {
      "Credit"  => 1,
      "Debit"   =>  -1
  }
  belongs_to :account
  belongs_to :salesperson

  # validate :sufficient_balance, true

  after_create :set_customer_account_balance

  def sufficient_balance
    if tran_type == "Debit"
      self.account.account_balance > self.amount
    else
      true
    end

  end

  def set_customer_account_balance
    Account.set_balance(self)
  end



end
