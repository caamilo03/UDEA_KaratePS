@parabank_accounts
Feature: Accounts in Parabank

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    //from login.feature
    * def authData = call read('login.feature')
    * def targetCustomerId = authData.customerId

    Scenario: Validate the schema and financial integrity of the accounts endpoint
      Given path 'customers', targetCustomerId, 'accounts'
      When method GET
      Then status 200
      
      * match each response ==
    """
      {
      id: '#number',
      customerId: '#(targetCustomerId)',
      type: '#regex ^(CHECKING|SAVINGS)$',
      balance: '#number'
    }
    """
    * def isNotNegative = function(x){ return x >= 0 }
    * def balances = $response[*].balance
    * match each balances == '#? isNotNegative(_)' 