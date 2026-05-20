@parabank_login
Feature: Login to Parabank

  Background:
    * url baseUrl
    * header Accept = 'application/json'

  Scenario: Customer Login
    Given path 'login'
    And path 'john' //userName
    And path 'demo' //password
    When method GET
    Then status 200
    And match response ==
    """
    {
       "id": '#number',
       "firstName": '#string',
       "lastName": '#string',
       "address": {
            "street": '#string',
            "city": '#string',
            "state": '#string',
            "zipCode": '#string'
        },
       "phoneNumber": '#string',
       "ssn": '#string'
    }
    """
    * match header Content-Type contains 'application/json'

    * def cookieHeader = responseHeaders['Set-Cookie'][0]

    * match cookieHeader contains 'JSESSIONID'

  Scenario: Customer Login with invalid credentials returns 401
    Given path 'login', 'john', 'wrongpassword'
    When method GET
    Then status 401

    
    * match response == {error: '#object'}
    