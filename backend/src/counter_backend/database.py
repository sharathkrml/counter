import sqlite3
from pathlib import Path
from contextlib import closing

from counter_backend.config import DATA_DIR, DATABASE_PATH


def _resolve(db_path):
    if db_path is None:
        return DATABASE_PATH
    return Path(db_path)


def initialize_database(db_path=None) -> None:
    path = _resolve(db_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    with closing(sqlite3.connect(path)) as db:
        with db:
            db.execute(
                """
                CREATE TABLE IF NOT EXISTS counter (
                    id INTEGER PRIMARY KEY CHECK (id = 1),
                    value INTEGER NOT NULL
                )
                """
            )
            db.execute(
                """
                INSERT OR IGNORE INTO counter (id, value)
                VALUES (1, 0)
                """
            )


def get_connection(db_path=None) -> sqlite3.Connection:
    path = _resolve(db_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    connection = sqlite3.connect(path, timeout=5)
    connection.row_factory = sqlite3.Row
    return connection
