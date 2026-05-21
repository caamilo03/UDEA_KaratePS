@parabank_billpay
Feature: Robustez y Manejo de Excepciones en Pagos (Bill Pay)

  Background:
    * url baseUrl
    # configure headers garantiza que Accept: application/json persista en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    # Login directo como prerequisito de setup (los criterios de login se validan en login.feature)
    Given path 'login', 'john', 'demo'
    When method GET
    Then status 200
    * def customerId = response.id
    # Obtener accountId y saldo disponible DINÁMICAMENTE desde el endpoint de cuentas
    Given path 'customers', customerId, 'accounts'
    When method GET
    Then status 200
    * def accountId = response[0].id
    * def saldoDisponible = response[0].balance

    # Payee válido en formato XML (requerido por la API de Parabank - no acepta JSON en este endpoint)
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

  Scenario: Pago exitoso con monto válido - valida esquema de respuesta
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
    # El criterio de aceptación exige que la API retorne 400 Bad Request (error de lógica de negocio)
    # para montos inválidos o superiores al saldo disponible, con un mensaje de error descriptivo.
    # DEFECTO DEL API: La API no valida el monto y retorna 200 OK en todos los casos de borde,
    # aceptando pagos con monto cero, negativo y mayor al saldo sin ninguna validación.
    Given path 'billpay'
    And param accountId = accountId
    And param amount = <monto>
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 400
    # DEFECTO DEL API: El criterio exige un mensaje de error descriptivo en el cuerpo de la respuesta.
    # La API retorna 200 con el pago procesado en lugar de rechazarlo con un error de negocio.

    Examples:
      | monto   | descripcion                                                               |
      | 0       | Monto cero: la API debe rechazar pagos de $0 con error de negocio         |
      | -50     | Monto negativo: la API debe rechazar montos negativos con error de negocio |
      | 9999999 | Saldo insuficiente: la API debe rechazar si el monto supera el saldo      |

  Scenario: Cuenta de origen inexistente debe retornar error de negocio 400, no error interno
    # El criterio exige 400 Bad Request con mensaje descriptivo para una cuenta inexistente.
    # DEFECTO DEL API: La API retorna 500 Internal Server Error, lo que expone un error interno
    # del servidor al cliente. Esto es además un defecto de seguridad (exposición de trazas internas).
    Given path 'billpay'
    And param accountId = 99999999
    And param amount = 10
    And header Content-Type = 'application/xml'
    And request payeeXml
    When method POST
    Then status 400
