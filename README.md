# Banking

## Environment

Dependencies
---------------------------
 * Docker
 * docker-compose
 * Python 2/3

### Generate docker files and required enviroment variables for both dev and production environments
```bash
$ cd devops
$ ./build_files.py
```
The output this command is print of generation files

```bash
$ cd dev
$ docker-compose up -d
$ docker-compose exec banking_app bash
```

### Runing Test
Before run test get all dependencies:

  * Install dependencies with `mix deps.get`

Inside on container run the following command

```bash
root@sd54f5d4$ MIX_ENV=test mix coveralls
```
or
```bash
root@sd54f5d4$ mix test --cover
```

### Running Server
To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server`

### Endpoints

**note:** All ammount fields should be filled like a integer data

e.g.: 100,00 -> 10000

`bank.postman_collection.json` on root directory contains all endpoint to import on Postman

### Unauthenticated routes

**POST** `localhost:4000/api/v1/signup`

Parameters Example:
```json
{
  "email": "some@email.com", 
  "password": "password",
  "name": "Some name"
}
```
Response
```json
{
  "id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "name": "Some name"
}
```
**POST** `localhost:4000/api/v1/signin`

Parameters Example:
```json
{
  "email": "some@email.com", 
  "password": "password"
}
```
Response (example)
```json
{
  "token": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJiYW5raW5nIiwiZXhwIjoxNTY2MjIzNTQ1LCJpYXQiOjE1NjM4MDQzNDUsImlzcyI6ImJhbmtpbmciLCJqdGkiOiIwMTE0ZGM4Yy04MjEzLTRlN2YtYWEwNC1mNGZhZjA4Y2FiMzIiLCJuYmYiOjE1NjM4MDQzNDQsInN1YiI6IjgyNWQ3ZjljLWRjNjUtNDA3Mi05OTAyLWZjNGIzNjhmYWQ1MiIsInR5cCI6ImFjY2VzcyJ9.rqhFmAeeH1dw7jRfhmI2AVLK9Sl9ZVXPCW8d1ls9Lq6Vj2WSaxts8HeMiajbD3NRnIq3m12MkQH5w4mMA_nv8g"
}
```
### Authenticated routes

**POST** `localhost:4000/api/v1/deposit`

Parameters Example:
```json
{
  "account_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "amount": 10000
}
```
Response (example)
```json
{
  "account_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "amount": "R$100.00",
  "date": "2019-07-22T14:23:32",
  "transaction_id": "a6594287-232f-40a0-b976-d7e4064b17f5",
  "type": "deposit"
}
```

**POST** `localhost:4000/api/v1/withdrawal`

Parameters Example:
```json
{
  "account_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "amount": 500
}
```
Response (example)
```json
{
  "account_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "amount": "R$-5.00",
  "date": "2019-07-22T14:36:09",
  "transaction_id": "b571ed98-22d4-480c-b338-47b6786ca9ca",
  "type": "withdrawal"
}
```

**POST** `localhost:4000/api/v1/transfer`

Parameters Example:
```json
{
  "account_from_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "account_to_id": "4eb5752b-08c7-4cee-be14-8bdfa48d1212",
  "amount": 9000
}
```
Response (example)
Success
```json
{
  "transactions": [
    {
      "account_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
      "amount": "R$-90.00",
      "date": "2019-07-22T14:33:52",
      "transaction_id": "97e8039c-2fd8-4490-bbaf-512da21d0955",
      "type": "transfer"
    },
    {
      "account_id": "4eb5752b-08c7-4cee-be14-8bdfa48d1212",
      "amount": "R$90.00",
      "date": "2019-07-22T14:33:52",
      "transaction_id": "b1832595-7d3a-4ab2-866a-e408f48a5c61",
      "type": "transfer"
    }
  ]
}
```
### Errors
1. Insuficient Funds
```json
{
  "errors": {
    "detail": {
      "message": "Transfer not allowed: Insuficient funds"
    }
  }
}
```
2. Account not found
```json
{
  "errors": {
    "detail": {
      "message": "Account not found"
    }
  }
}
```
2. Transfer from another account
```json
{
  "errors": {
    "detail": {
      "message": "You just make transfers from your account"
    }
  }
}
```

**GET** `localhost:4000/api/v1/balance/:account_id`

Parameters Example:

Without json paramenter

Response (example)
```json
{
  "account_id": "5eb60246-ede8-4bb4-8c05-9cdb56f170bd",
  "balance": "R$100.00"
}
```
Errors
```json
{
  "errors": {
    "detail": {
      "message": "Account not found"
    }
  }
}
```