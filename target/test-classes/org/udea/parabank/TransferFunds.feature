@parabank_transfer
Feature: Transferencia Atómica y Validación de Histórico

  Background:
    * url baseUrl
    # configure headers garantiza que Accept: application/json persista en todos los requests del escenario
    * configure headers = { Accept: 'application/json' }
    * def val_fromAccountId = '13899'
    * def val_toAccountId = '14565'
    * def val_amount = 50

  Scenario: Transferencia exitosa con validación de encadenamiento y libro mayor (ledger)
    # --- PASO 1: Ejecutar la transferencia ---
    Given path 'transfer'
    And param fromAccountId = val_fromAccountId
    And param toAccountId = val_toAccountId
    And param amount = val_amount
    When method POST
    Then status 200
    * def respuestaTransferencia = response

    # --- PASO 2: Encadenamiento - Verificación de Estado en el Libro Mayor ---
    # GET automático al historial de la cuenta destino para validar la transacción
    Given path 'accounts', val_toAccountId, 'transactions'
    When method GET
    Then status 200

    # La API retorna transacciones en orden ascendente por ID (más antigua primero).
    # Usamos JSONPath $[-1:] para obtener la más reciente de forma confiable.
    * def ultimaTransaccion = karate.jsonPath(response, '$[-1:]')[0]
    * match ultimaTransaccion.type == 'Credit'
    * match ultimaTransaccion.amount == val_amount

    # --- DEFECTO DEL API (Criterio de Encadenamiento): ---
    # El criterio exige que la respuesta del POST sea un objeto JSON con el ID de la transacción
    # resultante, para permitir el encadenamiento directo via GET /transactions/{transactionId}.
    # La API retorna texto plano sin ID, imposibilitando este encadenamiento según la especificación.
    * match respuestaTransferencia == { "transactionId": '#number' }
