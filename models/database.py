import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Any, Iterable, Iterator, Mapping, Sequence

_DB_FILENAME = "flowers.db"


def _find_project_root() -> Path:
    current = Path(__file__).resolve()
    for parent in [current] + list(current.parents):
        candidate = parent / _DB_FILENAME
        if candidate.exists():
            return candidate.parent
    return Path(__file__).resolve().parent.parent


def database_path() -> Path:
    return _find_project_root() / _DB_FILENAME


@contextmanager
def get_connection() -> Iterator[sqlite3.Connection]:
    path = database_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(path, detect_types=sqlite3.PARSE_DECLTYPES)
    connection.row_factory = sqlite3.Row
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def execute(query: str, params: Sequence[Any] | Mapping[str, Any] | None = None) -> None:
    with get_connection() as conn:
        bound = [] if params is None else params
        conn.execute(query, bound)


def executemany(query: str, seq_of_params: Iterable[Sequence[Any]]) -> None:
    with get_connection() as conn:
        conn.executemany(query, seq_of_params)


def fetch_all(query: str, params: Sequence[Any] | Mapping[str, Any] | None = None) -> list[sqlite3.Row]:
    with get_connection() as conn:
        bound = [] if params is None else params
        cursor = conn.execute(query, bound)
        return cursor.fetchall()


def fetch_one(query: str, params: Sequence[Any] | Mapping[str, Any] | None = None) -> sqlite3.Row | None:
    with get_connection() as conn:
        bound = [] if params is None else params
        cursor = conn.execute(query, bound)
        return cursor.fetchone()
