@parabank_login
Feature: Autenticación y Persistencia de Sesión en Parabank

  Background:
    * url baseUrl
    * header Accept = 'application/json'

  @login_ok
  Scenario: Login exitoso devuelve datos del cliente y gestiona la sesión
    Given path 'login', 'john', 'demo'
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

    # DEFECTO: El endpoint REST no emite Set-Cookie/JSESSIONID. La sesión solo existe vía formulario HTML.
    * def cookieHeader = responseHeaders['Set-Cookie'][0]
    * match cookieHeader contains 'JSESSIONID'

    * def customerId = response.id

  @login_fail
  Scenario: Credenciales incorrectas retornan 401 con esquema de error estandarizado
    Given path 'login', 'john', 'wrongpassword'
    When method GET
    # DEFECTO: RFC 7235 exige 401 Unauthorized. Parabank retorna 400 Bad Request.
    Then status 401
    # DEFECTO: Se esperaba JSON con campo 'error'. La API retorna texto plano (Content-Type: text/plain).
    * match response == {error: '#string'}
