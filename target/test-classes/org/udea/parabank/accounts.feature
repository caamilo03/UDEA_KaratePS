@parabank_accounts
Feature: Integridad de Datos en Consulta de Cuentas

  Background:
    * url baseUrl
    # configure headers garantiza que Accept: application/json persista en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    # Login directo como prerequisito de setup (los criterios de login se validan en login.feature)
    Given path 'login', 'john', 'demo'
    When method GET
    Then status 200
    * def targetCustomerId = response.id

  Scenario: Validar esquema e integridad financiera del endpoint de cuentas
    Given path 'customers', targetCustomerId, 'accounts'
    When method GET
    Then status 200

    # Validación de Esquema: cada objeto del array debe cumplir estrictamente el contrato
    * match each response ==
    """
    {
      id: '#number',
      customerId: '#(targetCustomerId)',
      type: '#regex ^(CHECKING|SAVINGS)$',
      balance: '#number'
    }
    """

    # Integridad Financiera: ningún balance debe ser negativo
    # DEFECTO DEL ENTORNO DEMO: El servidor demo de Parabank es compartido entre múltiples usuarios
    # y no resetea los datos entre ejecuciones. La cuenta acumula transferencias ajenas resultando
    # en saldo negativo. El criterio exige balance >= 0 para cuentas CHECKING/SAVINGS.
    * def isNotNegative = function(x){ return x >= 0 }
    * def balances = $response[*].balance
    * match each balances == '#? isNotNegative(_)'
