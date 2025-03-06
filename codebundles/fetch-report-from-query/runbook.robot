*** Settings ***
Documentation       Fetches report data from the Ternary default dashboard
Metadata            Author    stewartshea
Metadata            Display Name    Ternary Default Dashboard Metrics
Metadata            Supports    Ternary
Library             BuiltIn
Library             RW.Core
Library             RW.CLI
Library             RW.platform
Library             RW.Workspace
Library             OperatingSystem
Library             Ternary.Utils


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
    ...    description=The Ternary API URL
    ...    pattern=\w*
    ...    default=https://core-api.ternary.app/api
     Set Suite Variable    ${TERNARY_BASE_API_URL}    ${TERNARY_BASE_API_URL}
    ${TERNARY_APP_URL}=    RW.Core.Import User Variable    TERNARY_APP_URL
    ...    type=string
    ...    description=The Ternary App URL
    ...    pattern=\w*
    ...    default=https://my.ternary.app
     Set Suite Variable    ${TERNARY_APP_URL}    ${TERNARY_APP_URL}
    ${MATCH_THRESHOLD}=    RW.Core.Import User Variable    MATCH_THRESHOLD
    ...    type=string
    ...    description=The threshold, between 0 and 1, in which a the report name must match the query for fetching. 
    ...    pattern=\w*
    ...    example=0.7 (70% Match)
    ...    default=0.7
    Set Suite Variable    ${MATCH_THRESHOLD}    ${MATCH_THRESHOLD}   


    ${QUERY}=    RW.Core.Import User Variable    QUERY
    ...    type=string
    ...    description=The Ternary Tenant ID
    ...    pattern=\w*
    ...    default="Daily Cost by Service - Month-to-date"

    Set Suite Variable    ${env}    {"TERNARY_BASE_API_URL":"${TERNARY_BASE_API_URL}", "TERNARY_TENANT_ID":"${TERNARY_TENANT_ID.key}", "TERNARY_API_TOKEN":"${TERNARY_API_TOKEN}", "OUTPUT_DIR":"${OUTPUT_DIR}"}

*** Tasks ***
Fetch Ternary Report from Query
    [Documentation]    Calls GET ${TERNARY_BASE_API_URL}/alert-rules?tenantID=${TERNARY_TENANT_ID} using cURL.

    ${report_id}=    Set Variable     f1356d33-81b3-43e9-a7e9-e16cee1dce44  

    ${all_reports}=    RW.CLI.Run Cli
    ...    cmd=curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/reports?tenantID=${TERNARY_TENANT_ID.value}" > ${OUTPUT_DIR}/reports.json
    ...    env=${env}

    ${report_id_to_names}=    RW.CLI.Run Cli    
    ...    cmd=jq '[.reports[] | {id, name}]' ${OUTPUT_DIR}/reports.json
    ...    env=${env}
    ${found_match}=    Set Variable    0
    ${matching_reports}=          Ternary.Utils.Get Top Matches     ${report_id_to_names.stdout}    ${QUERY}    5
    FOR    ${match}    IN    @{matching_reports}
        IF     ${match['score']} > ${MATCH_THRESHOLD}
            ${found_match}=    Set Variable    1
            Log    Score=${match['score']}, ID=${match['id']}, Name=${match['name']}
            ${report_url}=     Set Variable    "${TERNARY_APP_URL}/report-builder/${match['id']}?tenantID=${TERNARY_TENANT_ID.value}" 
            RW.Core.Add Issue
            ...    severity=4
            ...    expected=None
            ...    actual=None
            ...    title=View Ternary Report `${match['name']}`
            ...    reproduce_hint=None
            ...    details=User asked for a report matching `${QUERY}`. `${match['name']}` was found with score ${match['score']} (between 0 -1)
            ...    next_steps=View the [Ternary Report URL](${report_url})
        END
    END
    IF     ${found_match} == 0
        RW.Core.Add Issue
        ...    severity=3
        ...    expected=None
        ...    actual=None
        ...    title=No Ternary Report Found Matching Query `${QUERY}`
        ...    reproduce_hint=None
        ...    details=User Query `${QUERY}` did not return any similar report names.
        ...    next_steps=Try a different query.\nVerify available report names.\nDrop the match threshold for search results (currently ${MATCH_THRESHOLD}).
    END