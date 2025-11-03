from __future__ import annotations

import argparse

from . import seed_data
from .database import execute, executemany, get_connection


CREATE_STATEMENTS = [
    """
    CREATE TABLE IF NOT EXISTS Statuses (
        StatusCode INTEGER PRIMARY KEY,
        StatusName TEXT NOT NULL UNIQUE
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS Positions (
        PositionCode INTEGER PRIMARY KEY,
        PositionName TEXT NOT NULL UNIQUE
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS Employees (
        EmployeeCode INTEGER PRIMARY KEY AUTOINCREMENT,
        Login TEXT NOT NULL UNIQUE,
        Password TEXT NOT NULL,
        Name TEXT NOT NULL,
        Surname TEXT NOT NULL,
        PositionCode INTEGER NOT NULL,
        FOREIGN KEY (PositionCode) REFERENCES Positions(PositionCode)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS Customers (
        PhoneNumber TEXT PRIMARY KEY,
        Login TEXT NOT NULL UNIQUE,
        Password TEXT NOT NULL,
        Name TEXT NOT NULL,
        Surname TEXT NOT NULL
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS Flowers (
        TypeFlowerCode INTEGER PRIMARY KEY AUTOINCREMENT,
        Name TEXT NOT NULL UNIQUE,
        StockCount INTEGER NOT NULL DEFAULT 0
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS Bouquets (
        BouquetCode INTEGER PRIMARY KEY AUTOINCREMENT,
        BouquetName TEXT NOT NULL,
        TypeFlowerCode INTEGER NOT NULL,
        Count INTEGER NOT NULL,
        Pack TEXT NOT NULL,
        Price REAL NOT NULL,
        FOREIGN KEY (TypeFlowerCode) REFERENCES Flowers(TypeFlowerCode)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS Orders (
        OrderCode INTEGER PRIMARY KEY AUTOINCREMENT,
        StatusCode INTEGER NOT NULL,
        CreationTime TEXT NOT NULL,
        ResolveTime TEXT,
        TotalPrice REAL NOT NULL,
        PhoneNumber TEXT NOT NULL,
        PickerCode INTEGER,
        FOREIGN KEY (StatusCode) REFERENCES Statuses(StatusCode),
        FOREIGN KEY (PhoneNumber) REFERENCES Customers(PhoneNumber),
        FOREIGN KEY (PickerCode) REFERENCES Employees(EmployeeCode)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS OrderItems (
        ItemCode INTEGER PRIMARY KEY AUTOINCREMENT,
        OrderCode INTEGER NOT NULL,
        BouquetCode INTEGER NOT NULL,
        Count INTEGER NOT NULL,
        FOREIGN KEY (OrderCode) REFERENCES Orders(OrderCode),
        FOREIGN KEY (BouquetCode) REFERENCES Bouquets(BouquetCode)
    )
    """,
]


STATUS_VALUES = [
    (1, "NEW"),
    (2, "PICKING"),
    (3, "READY"),
    (4, "ISSUED"),
]

POSITION_VALUES = [
    (1, "Administrator"),
    (2, "Picker"),
]


RESET_QUERIES = [
    "DROP TABLE IF EXISTS OrderItems",
    "DROP TABLE IF EXISTS Orders",
    "DROP TABLE IF EXISTS Bouquets",
    "DROP TABLE IF EXISTS Flowers",
    "DROP TABLE IF EXISTS Customers",
    "DROP TABLE IF EXISTS Employees",
    "DROP TABLE IF EXISTS Positions",
    "DROP TABLE IF EXISTS Statuses",
]


def reset_database() -> None:
    with get_connection() as conn:
        for query in RESET_QUERIES:
            conn.execute(query)


def create_schema() -> None:
    with get_connection() as conn:
        for query in CREATE_STATEMENTS:
            conn.execute(query)


def seed() -> None:
    create_schema()
    executemany("INSERT OR IGNORE INTO Statuses(StatusCode, StatusName) VALUES(?, ?)", STATUS_VALUES)
    executemany("INSERT OR IGNORE INTO Positions(PositionCode, PositionName) VALUES(?, ?)", POSITION_VALUES)

    seed_data.insert_employees()
    seed_data.insert_customers()
    seed_data.insert_flowers_and_bouquets()
    seed_data.insert_orders()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Initialise flowers database")
    parser.add_argument("--reset", action="store_true", help="Drop all tables before creating schema")
    parser.add_argument("--seed", action="store_true", help="Insert demo data")
    args = parser.parse_args()

    if args.reset:
        reset_database()

    create_schema()

    if args.seed:
        seed()
