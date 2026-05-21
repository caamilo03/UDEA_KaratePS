@parabank_billpay
Feature: Robustez y Manejo de Excepciones en Pagos (Bill Pay)

  Background:
    * url baseUrl
    # configure headers persiste Accept en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    # Login y obtención de cuenta como prerequisito de setup
    Given path 'login', 'john', 'demo'
    When method GET
    Then status 200
    * def customerId = response.id
    # Obtener accountId y saldo disponible dinámicamente
    Given path 'customers', customerId, 'accounts'
    When method GET
    Then status 200
    * def accountId = response[0].id
    * def saldoDisponible = response[0].balance

    # La API de Parabank requiere el body del payee en XML (no acepta JSON en /billpay)
    * def payeeXml =
    """
    <payee>
      <name>Proveedor de Prueba</name>
      <address>
        <street>Calle 123</street>
        <city>Medellín</city>
        <state>ANT</state>
        <zipCode>050001</zipCode>
      </address>
      <phoneNumber>310-000-0000</phoneNumber>
      <accountNumber>9999</accountNumber>
      <routingNumber>111000025</routingNumber>
    </payee>
    """

  Scenario: Pago exitoso con monto válido valida esquema de respuesta
    Given path 'billpay'
    And param accountId = accountId
    And param amount = 10
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 200
    And match response == { payeeName: '#string', amount: '#number', accountId: '#number' }
    And match response.accountId == accountId

  Scenario Outline: Validación de montos inválidos y saldo insuficiente - Data Driven
    # DEFECTO: El criterio exige 400 Bad Request para montos inválidos o superiores al saldo.
    # La API retorna 200 OK aceptando monto cero, negativo y mayor al saldo sin ninguna validación.
    Given path 'billpay'
    And param accountId = accountId
    And param amount = <monto>
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 400

    Examples:
      | monto   | descripcion                                        |
      | 0       | Monto cero: debe rechazarse con error de negocio   |
      | -50     | Monto negativo: debe rechazarse con error de negocio|
      | 9999999 | Saldo insuficiente: monto supera el saldo disponible|

  Scenario: Cuenta de origen inexistente debe retornar 400, no error interno del servidor
    # DEFECTO: La API retorna 500 Internal Server Error exponiendo trazas internas.
    # El criterio exige 400 Bad Request con mensaje descriptivo (no un error 5xx de servidor).
    Given path 'billpay'
    And param accountId = 99999999
    And param amount = 10
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 400
