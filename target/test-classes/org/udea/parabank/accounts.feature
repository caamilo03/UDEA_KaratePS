@parabank_accounts
Feature: Accounts in Parabank

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * def targetCustomerId = '12212'

    Scenario: Get accounts by customer ID
      Given path 'customers', targetCustomerId, 'accounts'
      When method GET
      Then status 200
      
      * match response ==
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
    * match each balances == '#? isNotNegative' 