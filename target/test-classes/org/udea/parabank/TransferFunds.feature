@parabank_transfer
Feature: Transferencia Atómica y Validación de Histórico

  Background:
    * url baseUrl
    * configure headers = { Accept: 'application/json' }
    # Usamos las cuentas que ya venían en el ejemplo del repo
    * def val_fromAccountId = '13899'
    * def val_toAccountId = '14565'
    * def val_amount = 50

  Scenario: Transferencia y validación en el libro mayor (ledger)
    # --- PASO 1: Ejecutar la transferencia ---
    Given path 'transfer'
    And param fromAccountId = val_fromAccountId
    And param toAccountId = val_toAccountId
    And param amount = val_amount
    When method POST
    Then status 200
    
    # DEFECTO DEL API (Sustentación): El criterio exige capturar el ID de la transacción, 
    # pero el endpoint de Parabank devuelve texto plano, no un objeto con ID.
    * match response contains "Successfully transferred $"

    # --- PASO 2: Encadenamiento y Verificación de Estado ---
    # Hacemos un GET automático al historial de la cuenta destino
    Given path 'accounts', val_toAccountId, 'transactions'
    When method GET
    Then status 200

    # Validamos mediante JSONPath que la última transacción coincida en monto y tipo (Credit).
    # NOTA: Parabank devuelve transacciones en orden ASCENDENTE por ID (más antigua primero),
    # por lo que la más reciente está en el ÚLTIMO índice, no en [0].
    # Usamos karate.jsonPath con $[-1:] para obtener el último elemento de forma confiable.
    * def lastTransaction = karate.jsonPath(response, '$[-1:]')[0]
    
    * match lastTransaction.type == 'Credit'
    * match lastTransaction.amount == val_amount