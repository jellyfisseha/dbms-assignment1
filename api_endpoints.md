# 📡 API Endpoints – E-commerce Store Database

This document lists the **sample REST API endpoints** that could be built on top of the `ecommerce_store` database schema.

---

## 👤 Customers
- `GET /api/customers` → Retrieve all customers
- `GET /api/customers/{id}` → Get details of a specific customer
- `POST /api/customers` → Create a new customer
- `PUT /api/customers/{id}` → Update customer information
- `DELETE /api/customers/{id}` → Delete a customer

---

## 📦 Products
- `GET /api/products` → Retrieve all products
- `GET /api/products/{id}` → Get details of a specific product
- `POST /api/products` → Add a new product
- `PUT /api/products/{id}` → Update product details
- `DELETE /api/products/{id}` → Delete a product

---

## 🛍️ Orders
- `GET /api/orders` → Retrieve all orders
- `GET /api/orders/{id}` → Get order details
- `POST /api/orders` → Create a new order
- `PUT /api/orders/{id}` → Update order status
- `DELETE /api/orders/{id}` → Cancel an order

---

## 💳 Payments
- `GET /api/payments` → List all payments
- `GET /api/payments/{id}` → Get payment details
- `POST /api/payments` → Record a new payment
- `PUT /api/payments/{id}` → Update payment information
- `DELETE /api/payments/{id}` → Delete payment record

---

## ⭐ Reviews
- `GET /api/reviews` → List all reviews
- `GET /api/reviews/{id}` → Get a specific review
- `POST /api/reviews` → Add a new review
- `PUT /api/reviews/{id}` → Update a review
- `DELETE /api/reviews/{id}` → Delete a review

---

📌 These endpoints are only documentation for how an API would interact with the database — they are not implemented in this project.
