@parabank_loan
Feature: Simulación de Préstamo con Evaluación de Riesgo

  Background:
    * url baseUrl
    # configure headers persiste Accept en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    # Login como prerequisito de setup
    Given path 'login', 'john', 'demo'
    When method GET
    Then status 200
    * def customerId = response.id
    # Obtener accountId dinámicamente
    Given path 'customers', customerId, 'accounts'
    When method GET
    Then status 200
    * def fromAccountId = response[0].id

  Scenario: Solicitud de préstamo con perfil válido - verificación de respuesta y fecha ISO-8601
    Given path 'requestLoan'
    And param customerId = customerId
    And param amount = 1000
    And param downPayment = 200
    And param fromAccountId = fromAccountId
    When method POST
    Then status 200

    # El campo responseDate no debe ser nulo
    * match response.responseDate != null

    # DEFECTO: El criterio exige que responseDate sea una fecha válida en formato ISO-8601
    # (ej. "2026-05-21T00:00:00Z"). La API retorna un Unix timestamp en milisegundos
    # (ej. 1779328197199), que es un número entero, no una cadena de fecha ISO-8601.
    * match response.responseDate == '#string'

  Scenario Outline: Evaluación de riesgo con diferentes perfiles de solicitud
    Given path 'requestLoan'
    And param customerId = customerId
    And param amount = <monto>
    And param downPayment = <cuota>
    And param fromAccountId = fromAccountId
    When method POST
    Then status 200

    # DEFECTO (Entorno Demo): El criterio exige que la lógica de aprobación evalúe
    # monto vs. cuota inicial. La cuenta del demo tiene saldo negativo por acumulación
    # de transferencias ajenas, lo que rechaza todos los perfiles con el mismo error:
    # "error.insufficient.funds.for.down.payment", impidiendo validar la lógica de negocio.
    * match response.approved == <aprobado>

    Examples:
      | monto   | cuota | aprobado | descripcion                                           |
      | 1000    | 500   | true     | Cuota alta (50%): regla de negocio debería aprobar    |
      | 1000    | 10    | false    | Cuota baja (1%): regla de negocio debe rechazar       |
      | 500     | 500   | false    | Cuota igual al monto: caso límite, debe rechazarse    |
