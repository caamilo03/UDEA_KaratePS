@parabank_transfer
Feature: Transferencia Atómica y Validación de Histórico

  Background:
    * url baseUrl
    # configure headers persiste Accept en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    * def val_fromAccountId = '13899'
    * def val_toAccountId = '14565'
    * def val_amount = 50

  Scenario: Transferencia exitosa con encadenamiento y validación del libro mayor (ledger)
    # Paso 1: Ejecutar la transferencia
    Given path 'transfer'
    And param fromAccountId = val_fromAccountId
    And param toAccountId = val_toAccountId
    And param amount = val_amount
    When method POST
    Then status 200
    * def respuestaTransferencia = response

    # Paso 2: GET automático al historial de la cuenta destino
    Given path 'accounts', val_toAccountId, 'transactions'
    When method GET
    Then status 200
    # Parabank retorna transacciones en orden ascendente; $[-1:] obtiene la más reciente
    * def ultimaTransaccion = karate.jsonPath(response, '$[-1:]')[0]
    * match ultimaTransaccion.type == 'Credit'
    * match ultimaTransaccion.amount == val_amount

    # DEFECTO (Encadenamiento): el criterio exige un JSON con el ID de la transacción resultante.
    # La API retorna texto plano sin ID, imposibilitando el encadenamiento directo por transactionId.
    * match respuestaTransferencia == { "transactionId": '#number' }
