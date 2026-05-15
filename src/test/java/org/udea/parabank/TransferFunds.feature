@parabank_transfer
Feature: Transfer funds in Parabank

  Background:
    * url baseUrl
    * header Accept = 'application/json'
    * def val_fromAccountId = '13899'
    * def val_toAccountId = '14565'
    * def fakerObj = new faker()
    * def val_amount = fakerObj.number().numberBetween(1, 200)
    * def val_fromAccountIdError = fakerObj.number().randomNumber(6, true)
    * def val_toAccountIdError = fakerObj.number().randomNumber(6, true)

  Scenario: Successful Transfer
    Given path 'transfer'
    And param fromAccountId = val_fromAccountId //cuenta origen
    And param toAccountId = val_toAccountId //cuenta destino
    And param amount = val_amount // monto a transferir
    When method POST
    Then status 200
    And match response == "Successfully transferred $" + val_amount + " from account #" + val_fromAccountId + " to account #" + val_toAccountId

  Scenario: Transfer Failed - Not found account
    Given path 'transfer'
    And param fromAccountId = val_fromAccountIdError //cuenta origen inexistente
    And param toAccountId = val_toAccountIdError //cuenta destino inexistente
    And param amount = val_amount // monto a transferir
    When method POST
    Then status 400
    And match response == "Could not find account number " + val_fromAccountIdError + " and/or " + val_toAccountIdError
