#lang dssl2

# HW1: DSSL2 Warmup

###
### ACCOUNTS
###

# an Account is either a checking or a saving account
let account_type? = OrC("checking", "savings")

class Account:
    let id
    let type
    let balance

    # Constructs an account with the given ID number, account type, and
    # balance. The balance cannot be negative.
    # Note: nat = natural number (0, 1, 2, etc)
    def __init__(self, id, type, balance):
        if balance < 0: error('Account: negative balance')
        if not account_type?(type): error('Account: unknown type')
        self.id = id
        self.type = type
        self.balance = balance

    # .get_balance() -> num?
    def get_balance(self): return self.balance

    # .get_id() -> nat?
    def get_id(self): return self.id

    # .get_type() -> account_type?
    def get_type(self): return self.type
    
    # .set_balance(num) -> NoneC
    def set_balance(self, num): 
        self.balance = self.balance + num

    # .deposit(num?) -> NoneC
    # Deposits `amount` in the account. `amount` must be non-negative.
    def deposit(self, amount: num?) -> NoneC:
        if amount < 0: 
            error("Deposit amount must be non negative")
        self.balance = self.balance + amount

    # .withdraw(num?) -> NoneC
    # Withdraws `amount` from the account. `amount` must be non-negative
    # and must not exceed the balance.
    def withdraw(self, amount: num?):
        if amount < 0: 
            error("Withdraw amount must be non negative")
        elif amount > self.balance: 
            error("Withdraw amount must not exceed the balance")
        self.balance = self.balance - amount

    # .transfer(num?, Account?) -> NoneC
    # Transfers the specified amount from this account to another. That is,
    # it subtracts `amount` from this account's balance and adds `amount`
    # to the `to` account's balance. `amount` must be non-negative.
    def transfer(self, amount: num?, to):
        if amount < 0:
            error("Transfer amount must be non negative")
        elif amount > self.balance:
            error("Transfer amount must not exceed the balance")
        to.set_balance(amount)
        self.balance = self.balance - amount
        
# Sample accounts
let account: Account?
let account2: Account?
let account3: Account?

# .initData() -> NoneC
# Initilazes an account to test on
def initData():
    account = Account(2, "checking", 1000)
    account2 = Account(3, "savings", 10000)
    account3 = Account (4, "checking", 0)    
    

test 'Account#withdraw':
    let account = Account(2, "checking", 37)
    assert account.get_balance() == 37
    account.withdraw(10)
    assert account.get_balance() == 27
    assert_error account.withdraw(-10)
    account.withdraw(27)
    assert account.get_balance() == 0
    assert_error account.withdraw(1)

test 'Account#deposit':
    initData() 
    account.deposit(50)
    assert account.get_balance() == 1050
    account2.deposit(67)
    assert account2.get_balance() == 10067
    account.deposit(0)
    assert account.get_balance() == 1050
    assert_error account.deposit(-5)
    
test 'Account#transfer':
    initData()
    account.transfer(1000, account2)
    assert account2.get_balance() == 11000
    assert account.get_balance() == 0
    account2.transfer(1000, account3)
    assert account2.get_balance() == 10000
    assert account3.get_balance() == 1000
    account3.transfer(0, account2)
    assert account3.get_balance() == 1000
    assert account2.get_balance() == 10000
    assert_error account3.transfer(-1, account2)
    assert_error account3.transfer(5000, account2)
    
###
### CUSTOMERS
###

# Customers have names and bank accounts.
struct customer:
    let name
    let bank_account

# max_account_id(VecC[customer?]) -> nat?
# Find the largest account id used by any of the given customers' accounts.
# Raise an error if no customers are provided.
def max_account_id(customers):
    if customers.len() == 0:
        error ("No customers are provided")
    let max = customers[0].bank_account.get_id()
    for elem in customers: 
        if elem.bank_account.get_id() > max: 
            max = elem.bank_account.get_id()
    return max

# open_account(str?, account_type?, VecC[customer?]) -> VecC[customer?]
# Produce a new vector of customers, with a new customer added. That new
# customer has the provided name, and their new account has the given type and
# a balance of 0. The id of the new account should be one more than the current
# maximum, or 1 for the first account created.
def open_account(name: str?, type, customers):
    let length = customers.len()
    let ans = vec(length + 1)
    let new_id = 1 if length == 0 else max_account_id(customers) + 1
    let new_cust = customer(name, Account(new_id, type, 0))
    for i in range(0, length):
        ans[i] = customers[i]
    ans[length] = new_cust
    return ans

           
# check_sharing(VecC[customer?]) -> bool
# Checks whether any of the given customers share an account number.
def check_sharing(customers):
    for i in range(len(customers)):
        for j in range(i + 1, len(customers)):
            if customers[i].bank_account.get_id() == customers[j].bank_account.get_id():
                return True
    return False

###
### CUSTOMER TEST DATA
###

let c1: customer?
let c2: customer?
let c3: customer?
let c4: customer?
let customers: VecC[customer?]

# .initCustomerData() -> NoneC
# Initializes customers to test on
def initCustomerData():
    c1 = customer("Ali", Account(2, "checking", 100))
    c2 = customer("Sam", Account(5, "savings", 200))
    c3 = customer("Zoe", Account(3, "checking", 0))
    c4 = customer("Manny", Account(5, "checking", 10))
    customers = [c1, c2, c3]


test 'max_account_id':
    initCustomerData()
    assert max_account_id(customers) == 5
    assert max_account_id([c1]) == 2
    assert_error max_account_id([])
    
    let front_max = [
        customer("A", Account(9, "checking", 0)),
        customer("B", Account(2, "savings", 0))
    ]
    assert max_account_id(front_max) == 9

    let duplicate_max = [
        customer("A", Account(5, "checking", 0)),
        customer("B", Account(5, "savings", 0)),
        customer("C", Account(1, "checking", 0))
    ]
    assert max_account_id(duplicate_max) == 5

test 'open_account':
    initCustomerData()

    let new_customers = open_account("NewGuy", "savings", customers)
    assert new_customers.len() == 4
    assert new_customers[3].name == "NewGuy"
    assert new_customers[3].bank_account.get_id() == 6
    assert new_customers[3].bank_account.get_type() == "savings"
    assert new_customers[3].bank_account.get_balance() == 0
    assert new_customers[0].bank_account.get_id() == 2
    assert new_customers[1].bank_account.get_id() == 5
    assert new_customers[2].bank_account.get_id() == 3
    assert_error open_account("Bad", "investing", customers)

    let first = open_account("First", "checking", [])
    assert first.len() == 1
    assert first[0].name == "First"
    assert first[0].bank_account.get_id() == 1
    assert first[0].bank_account.get_type() == "checking"
    assert first[0].bank_account.get_balance() == 0

test 'check_sharing':
    initCustomerData()
    assert check_sharing(customers) == False
    let shared = [c1, c2, c3, c4]
    assert check_sharing(shared) == True
    assert check_sharing([]) == False
    assert check_sharing([c1]) == False

    let non_adj = [
        customer("A", Account(7, "checking", 0)),
        customer("B", Account(1, "checking", 0)),
        customer("C", Account(7, "savings", 0))
    ]
    assert check_sharing(non_adj) == True
    
    let triple = [
        customer("A", Account(4, "checking", 0)),
        customer("B", Account(4, "savings", 0)),
        customer("C", Account(4, "checking", 0))
    ]
    assert check_sharing(triple) == True