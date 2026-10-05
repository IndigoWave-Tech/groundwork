// Two action groups, two audiences.
//   critical: something is down or at risk right now. Email and SMS.
//   warning:  something needs attention, but it can wait until morning. Email.
//
// Routing alerts by severity is the single most important decision in this
// blueprint. If everything pages, nothing does.

targetScope = 'resourceGroup'

@description('Naming suffix, <org>-<env>-<regionShort>.')
param suffix string

@description('Email addresses for critical alerts.')
param criticalEmails array

@description('SMS receivers for critical alerts: objects with countryCode and phoneNumber.')
param criticalSmsReceivers array

@description('Email addresses for warning alerts.')
param warningEmails array

@description('Tags for the action groups.')
param tags object

resource critical 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-critical-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'critical' // 12 character limit; appears in SMS
    enabled: true
    emailReceivers: [
      for (email, i) in criticalEmails: {
        name: 'email-${i}'
        emailAddress: email
        useCommonAlertSchema: true
      }
    ]
    smsReceivers: [
      for (sms, i) in criticalSmsReceivers: {
        name: 'sms-${i}'
        countryCode: sms.countryCode
        phoneNumber: sms.phoneNumber
      }
    ]
  }
}

resource warning 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-warning-${suffix}'
  location: 'global'
  tags: tags
  properties: {
    groupShortName: 'warning'
    enabled: true
    emailReceivers: [
      for (email, i) in warningEmails: {
        name: 'email-${i}'
        emailAddress: email
        useCommonAlertSchema: true
      }
    ]
  }
}

output criticalActionGroupId string = critical.id
output warningActionGroupId string = warning.id
