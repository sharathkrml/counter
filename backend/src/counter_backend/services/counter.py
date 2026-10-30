from contextlib import closing

from counter_backend.database import get_connection, initialize_database


class CounterService:
    def __init__(self, db_path=None):
        self.db_path = db_path

    def _initialize(self) -> None:
        initialize_database(self.db_path)

    def get_count(self) -> int:
        with closing(get_connection(self.db_path)) as db:
            row = db.execute(
                "SELECT value FROM counter WHERE id = 1"
            ).fetchone()
            return int(row["value"])

    def increment(self) -> int:
        with closing(get_connection(self.db_path)) as db:
            with db:
                db.execute("BEGIN IMMEDIATE")
                db.execute(
                    "UPDATE counter SET value = value + 1 WHERE id = 1"
                )
                row = db.execute(
                    "SELECT value FROM counter WHERE id = 1"
                ).fetchone()
                return int(row["value"])

    def decrement(self) -> int:
        with closing(get_connection(self.db_path)) as db:
            with db:
                db.execute("BEGIN IMMEDIATE")
                db.execute(
                    "UPDATE counter SET value = value - 1 WHERE id = 1"
                )
                row = db.execute(
                    "SELECT value FROM counter WHERE id = 1"
                ).fetchone()
                return int(row["value"])

    def reset(self) -> int:
        with closing(get_connection(self.db_path)) as db:
            with db:
                db.execute("BEGIN IMMEDIATE")
                db.execute(
                    "UPDATE counter SET value = 0 WHERE id = 1"
                )
        return 0
