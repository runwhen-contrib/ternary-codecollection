import json
from difflib import SequenceMatcher
from robot.api.deco import keyword

@keyword("Get Top Matches")
def get_top_matches(data_json, query, limit=5):
    """
    Get top 'limit' matches for 'query' from a JSON string 'data_json'.
    
    Example usage in Robot Framework:
    
        *** Settings ***
        Library    SearchLibrary.py

        *** Test Cases ***
        Example Test
            ${json_str}=    Catenate    SEPARATOR=    [
            ...    { "id": "123", "name": "Cost by Service - Last Month" },
            ...    { "id": "456", "name": "Daily Cost - Month-to-date" },
            ...    ]

            ${results}=    Get Top Matches    ${json_str}    cost over the last month    5
            Log Many    ${results}

    The returned list of dictionaries includes:
        - 'score' (float)  : The fuzzy matching ratio
        - 'id'    (string) : The matching item's ID
        - 'name'  (string) : The matching item's name
    """
    # Convert string to Python list of dicts
    data = json.loads(data_json)

    def similarity(a, b):
        return SequenceMatcher(None, a, b).ratio()

    query_lower = query.lower()
    scored_items = []

    for item in data:
        name_lower = item.get("name", "").lower()
        score = similarity(query_lower, name_lower)
        scored_items.append({
            'score': score,
            'id': item.get('id', ''),
            'name': item.get('name', '')
        })

    # Sort by descending similarity, return up to 'limit' items
    scored_items.sort(key=lambda x: x['score'], reverse=True)
    return scored_items[:limit]
