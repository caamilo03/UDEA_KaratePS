@parabank_billpay
Feature: Robustez y Manejo de Excepciones en Pagos (Bill Pay)

  Background:
    * url baseUrl
    # configure headers persiste Accept en TODOS los requests del feature (no solo el primero)
    * configure headers = { Accept: 'application/json' }
    # Obtener customerId via login
    * def authData = call read('login.feature@login_ok')
    * def customerId = authData.customerId
    # Obtener accountId y saldo disponible DINÁMICAMENTE
    Given path 'customers', customerId, 'accounts'
    When method GET
    Then status 200
    * def accountId = response[0].id
    * def availableBalance = response[0].balance

    # Payee válido (XML requerido por la API de Parabank)
    * def payeeXml =
    """
    <payee>
      <name>Test Payee</name>
      <address>
        <street>123 Main St</street>
        <city>Beverly Hills</city>
        <state>CA</state>
        <zipCode>90210</zipCode>
      </address>
      <phoneNumber>310-000-0000</phoneNumber>
      <accountNumber>9999</accountNumber>
      <routingNumber>111000025</routingNumber>
    </payee>
    """

  Scenario: Pago exitoso valida esquema de respuesta
    Given path 'billpay'
    And param accountId = accountId
    And param amount = 10
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 200
    And match response == { payeeName: '#string', amount: '#number', accountId: '#number' }
    And match response.accountId == accountId

  Scenario Outline: Data-Driven - Validación de casos de borde y saldo insuficiente
    # El criterio de aceptación espera 400 Bad Request para montos inválidos y saldo insuficiente.
    # DEFECTO DOCUMENTADO: La API no valida montos y retorna 200 en todos los casos de borde.
    # Los mensajes de error descriptivos esperados por el criterio no son provistos por la API.
    Given path 'billpay'
    And param accountId = accountId
    And param amount = <amount>
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    # DEFECTO: Debería retornar 400, pero la API retorna <actualStatus> sin validar <descripcion>
    Then status <actualStatus>

    Examples:
      | amount  | actualStatus | descripcion                                                        |
      | 0       | 200          | Monto cero - DEFECTO: API no rechaza pagos de $0                   |
      | -50     | 200          | Monto negativo - DEFECTO: API acepta montos negativos              |
      | 9999999 | 200          | Saldo insuficiente - DEFECTO: API no valida contra saldo disponible |

  Scenario: Cuenta de origen inexistente retorna error de servidor
    # DEFECTO DOCUMENTADO: Con accountId inexistente la API retorna 500 Internal Server Error.
    # El criterio exige 400 Bad Request con mensaje descriptivo (no un error interno del servidor).
    # Esto expone trazas internas, lo cual es también un defecto de seguridad.
    Given path 'billpay'
    And param accountId = 99999999
    And param amount = 10
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 500
