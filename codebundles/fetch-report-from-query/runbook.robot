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
Library             RW.RunSession
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

    ${SESSION}=    RW.Workspace.Import Runsession Details    
    Set Suite Variable    ${SESSION}    ${SESSION}

    ${QUERY}=    RW.Core.Import User Variable    QUERY
    ...    type=string
    ...    description=The Ternary Tenant ID
    ...    pattern=\w*
    ...    default="Daily Cost by Service - Month-to-date"
    Set Suite Variable    ${QUERY}    ${QUERY}
    Set Suite Variable    ${env}    {"TERNARY_BASE_API_URL":"${TERNARY_BASE_API_URL}", "TERNARY_TENANT_ID":"${TERNARY_TENANT_ID.value}"}

*** Tasks ***
Fetch Ternary Report from Query
    [Documentation]    Connects to Ternary and searches for reports that best match the user query. Returns a list of reports and urls. 
    [Tags]      access:read-only    cost    costanalysis    ternary    reports    finops

    ${session_list}=    Evaluate    json.loads(r'''${SESSION}''')    json
    ${search_query}=              Set Variable    ${session_list["runRequests"][0]["fromSearchQuery"]}
    IF    not $search_query or not $search_query.strip()
        Add Pre To Report    Could not find a query in RunSession, falling back to default configured query ${QUERY}
        ${REPORT_QUERY}=    Set Variable    ${QUERY}
    ELSE
        ${REPORT_QUERY}=    Set Variable    ${search_query}
    END    
    ${all_reports}=    RW.CLI.Run Bash File
    ...    bash_file=fetch_reports.sh
    # ...    cmd=curl -s -H "Content-Type: application/json" -K TERNARY_API_TOKEN "${TERNARY_BASE_API_URL}/reports?tenantID=${TERNARY_TENANT_ID.value}" > ${OUTPUT_DIR}/reports.json
    ...    env=${env}
    ...    secret_file__TERNARY_API_TOKEN=${TERNARY_API_TOKEN}
    ...    secret_file__TERNARY_TENANT_ID=${TERNARY_TENANT_ID}
    ${report_id_to_names}=    RW.CLI.Run Cli    
    ...    cmd=jq '[.reports[] | {id, name}]' reports.json
    ...    env=${env}
    ${report_names}=    RW.CLI.Run Cli    
    ...    cmd=echo '${report_id_to_names.stdout}' | jq -r '.[].name'
    ...    env=${env}
    ${found_match}=    Set Variable    0
    ${matching_reports}=          Ternary.Utils.Get Top Matches     ${report_id_to_names.stdout}    ${REPORT_QUERY}    5
    FOR    ${match}    IN    @{matching_reports}
        IF     ${match['score']} > ${MATCH_THRESHOLD}
            ${found_match}=    Set Variable    1
            Log    Score=${match['score']}, ID=${match['id']}, Name=${match['name']}

            ${report_url}=     Set Variable    ${TERNARY_APP_URL}/report-builder/${match['id']}?tenantID=${TERNARY_TENANT_ID.value} 
            ${report_data}=    RW.CLI.Run Cli
            ...    cmd=curl -s -H "Content-Type: application/json" -H "Authorization: Bearer ${TERNARY_API_TOKEN.value}" "${TERNARY_BASE_API_URL}/reports/${match['id']}" | jq . 
            ...    env=${env}
            Add Pre To Report    ${match['name']}\n${report_data.stdout}

            RW.Core.Add Issue
            ...    severity=3
            ...    expected=None
            ...    actual=None
            ...    title=View Ternary Report `${match['name']}`
            ...    reproduce_hint=None
            ...    details=User asked for a report matching `${REPORT_QUERY}`. `${match['name']}` was found with score ${match['score']} (between 0 -1)
            ...    next_steps=View the [Ternary Report URL](${report_url})
        END
    END
    IF     ${found_match} == 0
        RW.Core.Add Issue
        ...    severity=3
        ...    expected=None
        ...    actual=None
        ...    title=No Ternary Report Found Matching Query `${REPORT_QUERY}`
        ...    reproduce_hint=None
        ...    details=User Query `${REPORT_QUERY}` did not return any similar report names. Available reports are: \n${report_names.stdout}
        ...    next_steps=Try a different query.\nVerify available report names.\nDrop the match threshold for search results (currently ${MATCH_THRESHOLD}).
    END