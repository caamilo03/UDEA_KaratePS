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

    # Criterio de aceptación: extraer y validar el header Set-Cookie para asegurar que el JSESSIONID está presente.
    # DEFECTO DEL API: El endpoint REST /login/{user}/{pass} no emite el header Set-Cookie con JSESSIONID.
    # La sesión solo se crea via formulario HTML (/login.htm), no a través del endpoint REST.
    # La API no gestiona el ciclo de vida de la sesión como lo exige el criterio de aceptación.
    * def cookieHeader = responseHeaders['Set-Cookie'][0]
    * match cookieHeader contains 'JSESSIONID'

    * def customerId = response.id

  @login_fail
  Scenario: Credenciales incorrectas retornan 401 Unauthorized con esquema de error estandarizado
    Given path 'login', 'john', 'wrongpassword'
    When method GET
    # DEFECTO DEL API: El estándar REST (RFC 7235) y el criterio de aceptación exigen 401 Unauthorized
    # para credenciales inválidas. La API retorna 400 Bad Request, que es semánticamente incorrecto.
    Then status 401
    # DEFECTO DEL API: El criterio exige un JSON con campo 'error' estandarizado.
    # La API retorna texto plano "Invalid username and/or password" con Content-Type: text/plain.
    * match response == {error: '#string'}
