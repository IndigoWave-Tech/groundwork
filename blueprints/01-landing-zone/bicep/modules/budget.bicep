// Subscription-level monthly budget. This is a safety net, not cost
// management; Blueprint 05 (Cost Guardrails) builds the full picture.

targetScope = 'subscription'

param budgetName string
param amount int
param contactEmails array

// Budgets need a start date on the first of a month. Use the current month
// at deployment time so the template stays environment-free.
param startDate string = '${utcNow('yyyy-MM')}-01'

resource budget 'Microsoft.Consumption/budgets@2026-06-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
    }
    notifications: {
      actual50: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 50
        thresholdType: 'Actual'
        contactEmails: contactEmails
      }
      actual80: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        thresholdType: 'Actual'
        contactEmails: contactEmails
      }
      forecast100: {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        thresholdType: 'Forecasted'
        contactEmails: contactEmails
      }
    }
  }
}
