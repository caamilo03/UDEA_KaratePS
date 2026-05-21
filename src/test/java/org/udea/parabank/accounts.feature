@parabank_accounts
Feature: Integridad de Datos en Consulta de Cuentas

  Background:
    * url baseUrl
    # configure headers persiste Accept en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    # Login como prerequisito de setup (criterios de login se validan en login.feature)
    Given path 'login', 'john', 'demo'
    When method GET
    Then status 200
    * def targetCustomerId = response.id

  Scenario: Validar esquema e integridad financiera del endpoint de cuentas
    Given path 'customers', targetCustomerId, 'accounts'
    When method GET
    Then status 200

    # Validación de Esquema: cada objeto debe cumplir estrictamente el contrato del API
    * match each response ==
    """
    {
      id: '#number',
      customerId: '#(targetCustomerId)',
      type: '#regex ^(CHECKING|SAVINGS)$',
      balance: '#number'
    }
    """

    # DEFECTO: El entorno demo acumula transferencias entre usuarios sin resetear datos,
    # resultando en saldos negativos. El criterio exige balance >= 0 en cuentas CHECKING/SAVINGS.
    * def isNotNegative = function(x){ return x >= 0 }
    * def balances = $response[*].balance
    * match each balances == '#? isNotNegative(_)'
