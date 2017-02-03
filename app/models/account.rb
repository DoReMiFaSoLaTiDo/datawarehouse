class Account < ActiveRecord::Base
  belongs_to :customer
  has_many :transactions

  def self.set_balance(tran)
    acct = Account.find(tran.account_id)
    existing_balance = BigDecimal(acct.account_balance)
    amount = BigDecimal(tran.amount)

    if tran.tran_type == "Credit"
      acct.update_attribute(:account_balance,  existing_balance + amount )
    else
      acct.update_attributes(:account_balance => existing_balance - amount )
    end

  end

end
