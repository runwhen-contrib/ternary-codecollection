*** Settings ***
Documentation       Fetches report data from the Ternary default dashboard
Metadata            Author    stewartshea
Metadata            Display Name    Ternary Default Dashboard Metrics
Metadata            Supports    Ternary
Library             BuiltIn
Library             RW.Core
Library             RW.CLI
Library             RW.platform
Library             OperatingSystem

Suite Setup         Suite Initialization

*** Keywords ***
Suite Initialization
    ${TERNARY_API_TOKEN}=    RW.Core.Import Secret    TERNARY_API_TOKEN
    ...    type=string
    ...    description=The Ternary API user token
    ...    pattern=\w*
    ${TERNARY_TENANT_ID}=    RW.Core.Import Secret    TERNARY_TENANT_ID
    ...    type=string
    ...    description=The Ternary Tenant ID
    ...    pattern=\w*
    ${TERNARY_BASE_API_URL}=    RW.Core.Import User Variable    TERNARY_BASE_API_URL
    ...    type=string
    ...    description=The Ternary Tenant ID
    ...    pattern=\w*
    ...    default=https://core-api.ternary.app/api
    ${TERNARY_BASE_API_URL}=    RW.Core.Import User Variable    TERNARY_BASE_API_URL
    ...    type=string
    ...    description=The Ternary Tenant ID
    ...    pattern=\w*
    ...    default=https://core-api.ternary.app/api
    ${PATH}=    RW.Core.Import User Variable    PATH
    ...    type=string
    ...    description=The path beyond the base api url for the call
    ...    pattern=\w*
    ...    default=reports
    Set Suite Variable    ${TERNARY_BASE_API_URL}    ${TERNARY_BASE_API_URL}
    Set Suite Variable    ${env}    {"TERNARY_BASE_API_URL":"${TERNARY_BASE_API_URL}", "TERNARY_TENANT_ID":"${TERNARY_TENANT_ID.key}", "TERNARY_API_TOKEN":"${TERNARY_API_TOKEN}"}

*** Tasks ***
List Alert Rules For Tenant (cURL)
    [Documentation]    Calls GET ${TERNARY_BASE_API_URL}/alert-rules?tenantID=${TERNARY_TENANT_ID} using cURL.

    Log    Running cURL command: curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/azure-rate-recommendations?tenantID=${TERNARY_TENANT_ID.value}"
    ${raw_json}=    RW.CLI.Run Cli
    ...    cmd=curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/azure-rate-recommendations?tenantID=${TERNARY_TENANT_ID.value}"
    ...    env=${env}
    Add To Report    ${raw_json.stdout}

Get Last Month Total Spend (Net) for `${TERNARY_TENANT_ID}`
    [Documentation]    Calls GET ${TERNARY_BASE_API_URL}/alert-rules?tenantID=${TERNARY_TENANT_ID} using cURL.

    # Log    Running cURL command: curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/reports/${report_id}"
    # ${raw_json}=    RW.CLI.Run Cli
    # ...    cmd=curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/reports/${report_id}"
    # ...    env=${env}
    # Add To Report    ${raw_json.stdout}
    ${all_reports}=    RW.CLI.Run Cli
    ...    cmd=curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/reports?tenantID=${TERNARY_TENANT_ID.value}" | jq '[.reports[] | {id, name}]' 
    ...    env=${env}
    Add Pre To Report   ${all_reports.stdout}

