# Chinook Music Store

A GraphQL app demonstrating how to implement Relay efficiently with Elixir, Ecto and Dataloader.

## Getting Started

```bash
docker-compose up -d
mix ecto.setup
mix phx.server
```

## Run Tests

```
MIX_ENV=test mix ecto.setup
mix test
```

## GraphiQL

Visit http://localhost:4000/api/graphiql

## Authentication

Some resources require basic authentication to access.
The GraphQL endpoint uses HTTP Basic Authentication, copy one of the values from [staff-basic-auth.txt](./staff-basic-auth.txt) or [customer-basic-auth](./customer-basic-auth.txt) into an `Authorization` headers for access.

### Customers

Can only be accessed from their own account, the "General Manager", the "Sales Manager" or the "Sales Support Agent" assigned to the customer.

Invoices are scoped to the customer that they belong, following the same rules as Customers.

### Employees

Can only be accessed from their own account, their manager, one of their reports, the "General Manager" or one of their assigned customers.

## Relay

The [ChinookWeb.Relay](./lib/chinook_web/schema/relay.ex) module contains helpers for resolving Relay connections.

### Pagination

Unlike `Absinthe.Relay`, the `Chinook.Relay` module does not use `offset` based pagination.
Instead a `keyset` based pagination model is used.
This should generally perform better, utilising indices on the field being used to sort the records.

### Cursors

Cursors are encoded as `sort_field|primary_key_field|primary_key_value`

## Queries

Each entity defines as associted `Loader` module containing the logic used to process pagination and filtering parameters.

## Scoping
