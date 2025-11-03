from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass
from datetime import datetime
from typing import Any

from PySide6.QtCore import QObject, Signal, Slot

from models.database import execute, fetch_all, fetch_one, get_connection


@dataclass
class User:
    role: str
    name: str
    surname: str
    identifier: str


ROLE_CLIENT = "client"
ROLE_PICKER = "picker"
ROLE_ADMIN = "admin"

ROLE_BY_POSITION = {
    1: ROLE_ADMIN,
    2: ROLE_PICKER,
}

STATUS_FLOW = {
    1: 2,
    2: 3,
    3: 4,
}


class Backend(QObject):
    loginSucceeded = Signal(dict)
    loginFailed = Signal(str)
    catalogChanged = Signal(list)
    cartChanged = Signal(list, float)
    pickerOrdersChanged = Signal(list)
    receiptReady = Signal(dict)
    adminDataChanged = Signal(str, list)
    notification = Signal(str)

    def __init__(self) -> None:
        super().__init__()
        self._user: User | None = None
        self._cart: dict[int, int] = defaultdict(int)

    # ------------------------------------------------------------------
    # Authentication
    # ------------------------------------------------------------------
    @Slot(str, str)
    def login(self, login: str, password: str) -> None:
        login = login.strip()
        password = password.strip()
        if not login or not password:
            self.loginFailed.emit("Введите логин и пароль")
            return

        employee = fetch_one(
            "SELECT EmployeeCode, Login, Password, Name, Surname, PositionCode FROM Employees WHERE Login = ?",
            (login,),
        )
        if employee and employee["Password"] == password:
            role = ROLE_BY_POSITION.get(employee["PositionCode"], ROLE_PICKER)
            self._user = User(role=role, name=employee["Name"], surname=employee["Surname"], identifier=str(employee["EmployeeCode"]))
            self.loginSucceeded.emit({
                "role": role,
                "name": employee["Name"],
                "surname": employee["Surname"],
                "identifier": employee["EmployeeCode"],
            })
            return

        customer = fetch_one(
            "SELECT PhoneNumber, Login, Password, Name, Surname FROM Customers WHERE Login = ?",
            (login,),
        )
        if customer and customer["Password"] == password:
            self._user = User(role=ROLE_CLIENT, name=customer["Name"], surname=customer["Surname"], identifier=customer["PhoneNumber"])
            self.loginSucceeded.emit({
                "role": ROLE_CLIENT,
                "name": customer["Name"],
                "surname": customer["Surname"],
                "identifier": customer["PhoneNumber"],
            })
            return

        self.loginFailed.emit("Неверный логин или пароль")

    # ------------------------------------------------------------------
    # Client catalog
    # ------------------------------------------------------------------
    @Slot(str)
    def requestCatalog(self, query: str = "") -> None:
        sql = (
            """
            SELECT b.BouquetCode, b.BouquetName, b.Count, b.Pack, b.Price, f.StockCount
            FROM Bouquets b
            JOIN Flowers f ON f.TypeFlowerCode = b.TypeFlowerCode
            WHERE f.StockCount >= b.Count
            AND (:query = '' OR LOWER(b.BouquetName) LIKE '%' || LOWER(:query) || '%')
            ORDER BY b.BouquetName
            """
        )
        rows = fetch_all(sql, {"query": query})
        items = []
        for row in rows:
            items.append(
                {
                    "BouquetCode": row["BouquetCode"],
                    "BouquetName": row["BouquetName"],
                    "Count": row["Count"],
                    "Pack": row["Pack"],
                    "Price": row["Price"],
                    "StockCount": row["StockCount"],
                }
            )
        self.catalogChanged.emit(items)

    @Slot(int, int)
    def cartAdd(self, bouquet_code: int, count: int = 1) -> None:
        if bouquet_code <= 0 or count <= 0:
            return
        self._cart[bouquet_code] += count
        self._emit_cart()

    @Slot(int)
    def cartRemove(self, bouquet_code: int) -> None:
        if bouquet_code in self._cart:
            del self._cart[bouquet_code]
            self._emit_cart()

    @Slot()
    def cartClear(self) -> None:
        self._cart.clear()
        self._emit_cart()

    def _emit_cart(self) -> None:
        if not self._cart:
            self.cartChanged.emit([], 0.0)
            return

        placeholders = ",".join(["?"] * len(self._cart))
        rows = fetch_all(
            f"SELECT BouquetCode, BouquetName, Price FROM Bouquets WHERE BouquetCode IN ({placeholders})",
            tuple(self._cart.keys()),
        )
        total_price = 0.0
        items = []
        for row in rows:
            count = self._cart[row["BouquetCode"]]
            price = row["Price"] * count
            total_price += price
            items.append(
                {
                    "BouquetCode": row["BouquetCode"],
                    "BouquetName": row["BouquetName"],
                    "Count": count,
                    "Price": row["Price"],
                    "Total": price,
                }
            )
        self.cartChanged.emit(items, total_price)

    @Slot(result=float)
    def cartTotalPrice(self) -> float:
        total = 0.0
        for bouquet_code, count in self._cart.items():
            row = fetch_one("SELECT Price FROM Bouquets WHERE BouquetCode = ?", (bouquet_code,))
            if row:
                total += row["Price"] * count
        return total

    @Slot()
    def placeOrder(self) -> None:
        if not self._user or self._user.role != ROLE_CLIENT:
            self.notification.emit("Для оформления заказа необходимо войти как клиент")
            return
        if not self._cart:
            self.notification.emit("Корзина пуста")
            return

        bouquet_codes = list(self._cart.keys())
        placeholders = ",".join(["?"] * len(bouquet_codes))
        bouquet_rows = fetch_all(
            f"SELECT BouquetCode, Count FROM Bouquets WHERE BouquetCode IN ({placeholders})",
            tuple(bouquet_codes),
        )
        with get_connection() as conn:
            cursor = conn.cursor()
            total_price = self.cartTotalPrice()
            cursor.execute(
                "INSERT INTO Orders(StatusCode, CreationTime, TotalPrice, PhoneNumber) VALUES(1, ?, ?, ?)",
                (
                    datetime.now().isoformat(timespec="seconds"),
                    total_price,
                    self._user.identifier,
                ),
            )
            order_code = cursor.lastrowid
            for row in bouquet_rows:
                bouquet_code = row["BouquetCode"]
                count = self._cart.get(bouquet_code, 0)
                cursor.execute(
                    "INSERT INTO OrderItems(OrderCode, BouquetCode, Count) VALUES(?, ?, ?)",
                    (order_code, bouquet_code, count),
                )
                cursor.execute(
                    "UPDATE Flowers SET StockCount = StockCount - ? WHERE TypeFlowerCode = (SELECT TypeFlowerCode FROM Bouquets WHERE BouquetCode = ?)",
                    (row["Count"] * count, bouquet_code),
                )
        self.cartClear()
        self.notification.emit("Заказ успешно создан")
        self.requestCatalog("")

    # ------------------------------------------------------------------
    # Picker UI
    # ------------------------------------------------------------------
    @Slot()
    def requestPickerOrders(self) -> None:
        sql = (
            """
            SELECT o.OrderCode, o.StatusCode, s.StatusName, o.CreationTime, o.ResolveTime, o.TotalPrice,
                   c.Name AS CustomerName, c.Surname AS CustomerSurname
            FROM Orders o
            JOIN Statuses s ON s.StatusCode = o.StatusCode
            JOIN Customers c ON c.PhoneNumber = o.PhoneNumber
            WHERE o.StatusCode IN (1, 2, 3)
            ORDER BY o.CreationTime ASC
            """
        )
        rows = fetch_all(sql)
        self.pickerOrdersChanged.emit([dict(row) for row in rows])

    @Slot(int)
    def advanceOrderStatus(self, order_code: int) -> None:
        row = fetch_one("SELECT StatusCode FROM Orders WHERE OrderCode = ?", (order_code,))
        if not row:
            return
        status = row["StatusCode"]
        if status not in STATUS_FLOW:
            return
        new_status = STATUS_FLOW[status]
        resolve_time = datetime.now().isoformat(timespec="seconds") if new_status == 4 else None
        with get_connection() as conn:
            conn.execute(
                "UPDATE Orders SET StatusCode = ?, ResolveTime = COALESCE(?, ResolveTime) WHERE OrderCode = ?",
                (new_status, resolve_time, order_code),
            )
        if new_status == 4:
            self._emit_receipt(order_code)
        self.requestPickerOrders()

    def _emit_receipt(self, order_code: int) -> None:
        order = fetch_one(
            """
            SELECT o.OrderCode, o.CreationTime, o.ResolveTime, o.TotalPrice,
                   c.Name, c.Surname
            FROM Orders o
            JOIN Customers c ON c.PhoneNumber = o.PhoneNumber
            WHERE o.OrderCode = ?
            """,
            (order_code,),
        )
        items = fetch_all(
            """
            SELECT b.BouquetName, b.Price, oi.Count
            FROM OrderItems oi
            JOIN Bouquets b ON b.BouquetCode = oi.BouquetCode
            WHERE oi.OrderCode = ?
            """,
            (order_code,),
        )
        payload = {
            "order": dict(order) if order else {},
            "items": [dict(item) for item in items],
        }
        self.receiptReady.emit(payload)

    # ------------------------------------------------------------------
    # Admin UI
    # ------------------------------------------------------------------
    @Slot(str)
    def requestAdminData(self, section: str) -> None:
        queries = {
            "orders": "SELECT * FROM Orders ORDER BY CreationTime DESC",
            "customers": "SELECT * FROM Customers ORDER BY Surname",
            "employees": "SELECT * FROM Employees ORDER BY Surname",
            "bouquets": "SELECT * FROM Bouquets ORDER BY BouquetName",
            "flowers": "SELECT * FROM Flowers ORDER BY Name",
        }
        query = queries.get(section)
        if not query:
            return
        rows = fetch_all(query)
        self.adminDataChanged.emit(section, [dict(row) for row in rows])

    @Slot(str, 'QVariantMap')
    def saveAdminRecord(self, section: str, payload: dict[str, Any]) -> None:
        handlers = {
            "customers": self._save_customer,
            "employees": self._save_employee,
            "bouquets": self._save_bouquet,
            "flowers": self._save_flower,
            "orders": self._save_order,
        }
        handler = handlers.get(section)
        if handler:
            handler(payload)
            self.requestAdminData(section)

    @Slot(str, int)
    def deleteAdminRecord(self, section: str, identifier: int) -> None:
        handlers = {
            "customers": self._delete_customer,
            "employees": self._delete_employee,
            "bouquets": self._delete_bouquet,
            "flowers": self._delete_flower,
            "orders": self._delete_order,
        }
        handler = handlers.get(section)
        if handler:
            handler(identifier)
            self.requestAdminData(section)

    # -- CRUD helpers ---------------------------------------------------
    def _save_customer(self, payload: dict[str, Any]) -> None:
        with get_connection() as conn:
            conn.execute(
                """
                INSERT INTO Customers(PhoneNumber, Login, Password, Name, Surname)
                VALUES(?, ?, ?, ?, ?)
                ON CONFLICT(PhoneNumber) DO UPDATE SET
                    Login=excluded.Login,
                    Password=excluded.Password,
                    Name=excluded.Name,
                    Surname=excluded.Surname
                """,
                (
                    payload.get("PhoneNumber"),
                    payload.get("Login"),
                    payload.get("Password"),
                    payload.get("Name"),
                    payload.get("Surname"),
                ),
            )

    def _delete_customer(self, identifier: int | str) -> None:
        execute("DELETE FROM Customers WHERE PhoneNumber = ?", (identifier,))

    def _save_employee(self, payload: dict[str, Any]) -> None:
        with get_connection() as conn:
            conn.execute(
                """
                INSERT INTO Employees(EmployeeCode, Login, Password, Name, Surname, PositionCode)
                VALUES(?, ?, ?, ?, ?, ?)
                ON CONFLICT(EmployeeCode) DO UPDATE SET
                    Login=excluded.Login,
                    Password=excluded.Password,
                    Name=excluded.Name,
                    Surname=excluded.Surname,
                    PositionCode=excluded.PositionCode
                """,
                (
                    payload.get("EmployeeCode"),
                    payload.get("Login"),
                    payload.get("Password"),
                    payload.get("Name"),
                    payload.get("Surname"),
                    payload.get("PositionCode", 2),
                ),
            )

    def _delete_employee(self, identifier: int) -> None:
        execute("DELETE FROM Employees WHERE EmployeeCode = ?", (identifier,))

    def _save_bouquet(self, payload: dict[str, Any]) -> None:
        with get_connection() as conn:
            conn.execute(
                """
                INSERT INTO Bouquets(BouquetCode, BouquetName, TypeFlowerCode, Count, Pack, Price)
                VALUES(?, ?, ?, ?, ?, ?)
                ON CONFLICT(BouquetCode) DO UPDATE SET
                    BouquetName=excluded.BouquetName,
                    TypeFlowerCode=excluded.TypeFlowerCode,
                    Count=excluded.Count,
                    Pack=excluded.Pack,
                    Price=excluded.Price
                """,
                (
                    payload.get("BouquetCode"),
                    payload.get("BouquetName"),
                    payload.get("TypeFlowerCode"),
                    payload.get("Count"),
                    payload.get("Pack"),
                    payload.get("Price"),
                ),
            )

    def _delete_bouquet(self, identifier: int) -> None:
        execute("DELETE FROM Bouquets WHERE BouquetCode = ?", (identifier,))

    def _save_flower(self, payload: dict[str, Any]) -> None:
        with get_connection() as conn:
            conn.execute(
                """
                INSERT INTO Flowers(TypeFlowerCode, Name, StockCount)
                VALUES(?, ?, ?)
                ON CONFLICT(TypeFlowerCode) DO UPDATE SET
                    Name=excluded.Name,
                    StockCount=excluded.StockCount
                """,
                (
                    payload.get("TypeFlowerCode"),
                    payload.get("Name"),
                    payload.get("StockCount", 0),
                ),
            )

    def _delete_flower(self, identifier: int) -> None:
        execute("DELETE FROM Flowers WHERE TypeFlowerCode = ?", (identifier,))

    def _save_order(self, payload: dict[str, Any]) -> None:
        resolve_time = payload.get("ResolveTime")
        with get_connection() as conn:
            conn.execute(
                """
                INSERT INTO Orders(OrderCode, StatusCode, CreationTime, ResolveTime, TotalPrice, PhoneNumber, PickerCode)
                VALUES(?, ?, ?, ?, ?, ?, ?)
                ON CONFLICT(OrderCode) DO UPDATE SET
                    StatusCode=excluded.StatusCode,
                    CreationTime=excluded.CreationTime,
                    ResolveTime=excluded.ResolveTime,
                    TotalPrice=excluded.TotalPrice,
                    PhoneNumber=excluded.PhoneNumber,
                    PickerCode=excluded.PickerCode
                """,
                (
                    payload.get("OrderCode"),
                    payload.get("StatusCode", 1),
                    payload.get("CreationTime"),
                    resolve_time,
                    payload.get("TotalPrice", 0.0),
                    payload.get("PhoneNumber"),
                    payload.get("PickerCode"),
                ),
            )

    def _delete_order(self, identifier: int) -> None:
        row = fetch_one("SELECT StatusCode FROM Orders WHERE OrderCode = ?", (identifier,))
        if not row:
            return
        if row["StatusCode"] != 4:
            items = fetch_all("SELECT BouquetCode, Count FROM OrderItems WHERE OrderCode = ?", (identifier,))
            with get_connection() as conn:
                for item in items:
                    bouquet = fetch_one(
                        "SELECT TypeFlowerCode, Count FROM Bouquets WHERE BouquetCode = ?",
                        (item["BouquetCode"],),
                    )
                    if bouquet:
                        conn.execute(
                            "UPDATE Flowers SET StockCount = StockCount + ? WHERE TypeFlowerCode = ?",
                            (bouquet["Count"] * item["Count"], bouquet["TypeFlowerCode"]),
                        )
        execute("DELETE FROM OrderItems WHERE OrderCode = ?", (identifier,))
        execute("DELETE FROM Orders WHERE OrderCode = ?", (identifier,))
