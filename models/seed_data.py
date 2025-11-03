from __future__ import annotations

import random
from datetime import datetime, timedelta
from typing import Iterable

from .database import executemany, fetch_all


def _random_name(prefix: str, index: int) -> str:
    return f"{prefix}{index:02d}"


def insert_employees() -> None:
    employees = [
        ("admin", "admin", "Ирина", "Кузнецова", 1),
        ("picker", "picker", "Олег", "Громов", 2),
        ("picker2", "picker", "Анна", "Лебедева", 2),
        ("picker3", "picker", "Михаил", "Титов", 2),
    ]
    executemany(
        "INSERT OR IGNORE INTO Employees(Login, Password, Name, Surname, PositionCode) VALUES(?, ?, ?, ?, ?)",
        employees,
    )


def insert_customers(count: int = 25) -> None:
    customers = []
    for index in range(1, count + 1):
        phone = f"+79{index:09d}"
        login = f"client{index:02d}"
        password = "client"
        name = f"Клиент{index:02d}"
        surname = f"Флора{index:02d}"
        customers.append((phone, login, password, name, surname))
    executemany(
        "INSERT OR IGNORE INTO Customers(PhoneNumber, Login, Password, Name, Surname) VALUES(?, ?, ?, ?, ?)",
        customers,
    )


def insert_flowers_and_bouquets() -> None:
    flowers = []
    bouquets = []
    flower_names = [
        "Роза красная",
        "Роза белая",
        "Тюльпан",
        "Гербера",
        "Пион",
        "Хризантема",
    ]
    for name in flower_names:
        stock = random.randint(50, 150)
        flowers.append((name, stock))
    executemany("INSERT OR IGNORE INTO Flowers(Name, StockCount) VALUES(?, ?)", flowers)

    existing_flowers = fetch_all("SELECT TypeFlowerCode, Name FROM Flowers")
    for index in range(1, 31):
        flower = random.choice(existing_flowers)
        bouquets.append(
            (
                f"Букет №{index:02d}",
                flower["TypeFlowerCode"],
                random.randint(3, 11),
                random.choice(["Крафт", "Корзина", "Лента", "Коробка"]),
                random.randint(900, 4500),
            )
        )
    executemany(
        """
        INSERT INTO Bouquets(BouquetName, TypeFlowerCode, Count, Pack, Price)
        VALUES(?, ?, ?, ?, ?)
        """,
        bouquets,
    )


def insert_orders(count: int = 30) -> None:
    customers = fetch_all("SELECT PhoneNumber FROM Customers")
    employees = fetch_all("SELECT EmployeeCode FROM Employees WHERE PositionCode = 2")
    bouquets = fetch_all("SELECT BouquetCode, Price FROM Bouquets")
    if not customers or not employees or not bouquets:
        return

    orders = []
    order_items: list[tuple[int, int, int]] = []
    now = datetime.now()
    for index in range(1, count + 1):
        customer = random.choice(customers)["PhoneNumber"]
        picker_code = random.choice(employees)["EmployeeCode"]
        status_code = random.choice([1, 2, 3, 4])
        creation_time = now - timedelta(days=random.randint(0, 30), hours=random.randint(0, 12))
        resolve_time = creation_time + timedelta(hours=random.randint(1, 48)) if status_code == 4 else None
        order_bouquets = random.sample(bouquets, k=random.randint(1, min(3, len(bouquets))))
        total_price = 0
        for bouquet in order_bouquets:
            count_items = random.randint(1, 3)
            total_price += bouquet["Price"] * count_items
        orders.append(
            (
                status_code,
                creation_time.isoformat(timespec="seconds"),
                resolve_time.isoformat(timespec="seconds") if resolve_time else None,
                total_price,
                customer,
                picker_code,
            )
        )

    executemany(
        """
        INSERT INTO Orders(StatusCode, CreationTime, ResolveTime, TotalPrice, PhoneNumber, PickerCode)
        VALUES(?, ?, ?, ?, ?, ?)
        """,
        orders,
    )

    created_orders = fetch_all("SELECT OrderCode FROM Orders ORDER BY OrderCode DESC LIMIT ?", (count,))
    order_codes = [row["OrderCode"] for row in created_orders]
    for order_code in order_codes:
        bouquet_choices = random.sample(bouquets, k=random.randint(1, min(3, len(bouquets))))
        for bouquet in bouquet_choices:
            order_items.append((order_code, bouquet["BouquetCode"], random.randint(1, 3)))
    executemany(
        "INSERT INTO OrderItems(OrderCode, BouquetCode, Count) VALUES(?, ?, ?)",
        order_items,
    )

