import json
from difflib import SequenceMatcher
from robot.api.deco import keyword

_WRAPPERS = {
    '[': ']',
    '{': '}',
    '(': ')',
    '<': '>',
    '"': '"',
    "'": "'",
}

def _unwrap(text: str) -> str:
    """Strip repeated symmetric wrappers like [], '', {}, etc., plus surrounding whitespace."""
    t = text.strip()
    while len(t) >= 2 and t[0] in _WRAPPERS and t[-1] == _WRAPPERS[t[0]]:
        t = t[1:-1].strip()
    return t

def get_top_matches(data_json: str, query: str, limit: int = 5):
    """
    Return up to `limit` best matches for `query` against the JSON list of
    objects (each having id and name).  Each result dict has keys: score, id, name.
    """
    data = json.loads(data_json)

    clean_query = _unwrap(query).lower()

    def similarity(a: str, b: str) -> float:
        return SequenceMatcher(None, a, b).ratio()

    scored = []
    for item in data:
        raw_name = item.get("name", "")
        clean_name = _unwrap(raw_name).lower()
        scored.append(
            {
                "score": similarity(clean_query, clean_name),
                "id": item.get("id", ""),
                "name": raw_name,          # keep original for display
            }
        )

    return sorted(scored, key=lambda x: x["score"], reverse=True)[:limit]