# Strichliste API

## API endpoints

### GET /user


#### Description

Returns a list of user objects.

Note: This response is Pageable. See #Pagination

```json
{
  "users": [
    {
      "id": 1,
      "name": "schinken",
      "active": true,
      "email": "foo@bar.de",
      "balance": 233,
      "created": "2018-08-17 16:20:57",
      "updated": "2018-08-17 16:22:41"
    },
    { }, { }, { }
  ]
}
```

### POST /user

#### Description

Create a new user

#### Example

```json
{
  "name": "Username",
  "email": "foo@bar.de"
}
```

#### Request-Parameters

|  field  | datatype    | description                   |
|---------|-------------|-------------------------------|
| name    | string      | username                      |
| email   | string      | e-mail address (optional )    |

#### Response

Returns the created `User-Object`

#### Errors

* UserAlreadyExistsException

### GET /user/{userId}

#### Description

Returns the user details for a given `userId`.

Note: You can access this resource using the `id` or `name` as userId

#### Response

Returns the `User-Object`

#### Example

```json
{
  "user": { }
}
```

#### Errors

* UserNotFoundException

### GET /user/{userId}/transaction

#### Description

Access the user's transactions for a given `userId`

Note: You can access this resource using the `id` or `name` as userId. This response is Pageable. See #Pagination

#### Example

```json
{
  "transactions": [
    {
      "id": 3,
      "user": {
        "id": 1,
        "name": "schinken",
        "active": true,
        "email": "foo@bar.de",
        "balance": 233,
        "created": "2018-08-17 16:20:57",
        "updated": "2018-08-17 16:22:41"
      },
      "article": null,
      "recipient": null,
      "sender": null,
      "comment": null,
      "amount": 33,
      "deleted": false,
      "isDeletable": true,
      "created": "2018-08-17 16:22:41"
    },
    { }, { }, { }
  ]
}
```

#### Response

Returns a list of transactions as a `Transaction-Object`

#### Errors

* UserNotFoundException

### GET /user/{userId}/transaction/{transactionId}

#### Description

Access a specific transactions

#### Example

```json
{
  "transaction": {
    "id": 3,
    "user": {
      "id": 1,
      "name": "schinken",
      "active": true,
      "email": "foo@bar.de",
      "balance": 233,
      "created": "2018-08-17 16:20:57",
      "updated": "2018-08-17 16:22:41"
    },
    "article": null,
    "recipient": null,
    "sender": null,
    "comment": null,
    "amount": 33,
    "deleted": false,
    "isDeletable": true,
    "created": "2018-08-17 16:22:41"
  }
}
```

#### Response

Returns a `Transaction-Object`

#### Errors

* UserNotFoundException
* TransactionNotFoundException

### DELETE /user/{userId}/transaction/{transactionId}

#### Description

Deletes a specific transaction

#### Example

```json
{
  "transaction": {
    "id": 42,
    "user": {
      "id": 1,
      "name": "schinken",
      "active": true,
      "email": "foo@bar.de",
      "balance": 233,
      "created": "2018-08-17 16:20:57",
      "updated": "2018-08-17 16:22:41"
    },
    "article": null,
    "recipient": null,
    "sender": null,
    "comment": null,
    "amount": 33,
    "deleted": true,
    "isDeletable": false,
    "created": "2018-08-17 16:22:41"
  }
}
```

#### Response

Returns a `Transaction-Object` with deleted: false, if transaction only gets deactivated, or with id: null, if it's deleted
from the database

#### Errors

* UserNotFoundException
* TransactionNotFoundException
* TransactionNotDeletableException

### POST /user/{userId}

#### Description

Updates user

#### Example

```json
{
  "name": "Username",
  "email": "foo@bar.de",
  "active": false
}
```

#### Request-Parameters

|  field  | datatype    | description                   |
|---------|-------------|-------------------------------|
| name    | string      | username                      |
| email   | string      | e-mail address (optional)     |
| active  | boolean     | active/inactive               |

#### Response

Returns the created `User-Object`

#### Errors

* UserNotFoundException
* UserAlreadyExistsException
* ParameterMissingException
* ParameterInvalidException

### POST /user/{userId}/transaction

#### Description

Create a transaction for the given `userId`

Note: You can access this resource using the `id` or `name` as userId

#### Example

```json
{
  "amount": 123,
  "quantity": 1,
  "articleId": 1,
  "recipientId": 2,
  "comment": "Foobar!"
}
```

|  field      | datatype | description                                         |
|-------------|----------|-----------------------------------------------------|
| amount      | integer  | amount in cents                                     |
| quantity    | integer  | quantity of the article (optional)                  |
| articleId   | integer  | id of an article (optional)                         |
| recipientId | integer  | userId of recipient (optional)                      |
| comment     | string   | comment (optional)                                  |

If an `articleId` is provided, the `amount` parameter overwrites the article amount.
`quantity` is only used if an `articleId` is provided - otherwise ignored.

#### Response

Returns a `Transaction-Object`

#### Errors

* UserNotFoundException
* ParameterMissingException
* ParameterInvalidException
* AccountBalanceBoundaryException
* TransactionBoundaryException

### GET /user/search

#### Description

Search users by name

```json
{
  "count": 5,
  "users": [
    {
      "id": 1,
      "name": "schinken",
      "active": true,
      "email": "foo@bar.de",
      "balance": 233,
      "created": "2018-08-17 16:20:57",
      "updated": "2018-08-17 16:22:41"
    },
    { }, { }, { }
  ]
}
```

#### Request-Parameters

|  field  | datatype    | description                   |
|---------|-------------|-------------------------------|
| query   | string      | search by name                |
| limit   | int         | max results (default: 25)     |

### GET /article

#### Description

Returns all available articles. Optionally you can provide `barcode` query parameter to filter by barcode.

Note: This response is Pageable. See #Pagination

#### Example

```json
{
  "articles": [
    {
      "id": 2,
      "name": "Club Mate",
      "barcode": "13373243",
      "amount": 100,
      "active": true,
      "usageCount": 0,
      "precursor": null,
      "created": "2018-08-17 14:21:25"
    },
    {}, {}, {}
  ]
}
```

#### Response

Returns a list of articles as a `Article-Object`

### POST /article

#### Description

Create a new article

#### Example

```json
{
  "name": "Club Mate Cola",
  "amount": 100,
  "barcode": "13374223"
}
```

#### Request-Parameters

|  field  | datatype    | description                   |
|---------|-------------|-------------------------------|
| name    | string      | article name                  |
| amount  | integer     | amount in cents               |
| barcode | string      | barcode (optional)            |

#### Response

Returns the created `Article-Object`

#### Errors

* ParameterInvalidException
* ParameterMissingException

### POST /article/{articleId}

#### Description

Updated an article. If you update an article, a new one is created with the reference to the old, deactivated one to maintain referencial integrity.

#### Example

```json
{
  "name": "Club Mate Cola",
  "amount": 100,
  "barcode": "13374223"
}
```

#### Request-Parameters

|  field  | datatype    | description                   |
|---------|-------------|-------------------------------|
| name    | string      | article name                  |
| amount  | integer     | amount in cents               |
| barcode | string      | barcode (optional)            |

#### Response

Returns the newly created `Article-Object`, with the old one as precursor.

#### Errors

* ArticleNotFoundException
* ParameterInvalidException
* ParameterMissingException

### DELETE /article/{articleId}

#### Description

Deletes an article. (Actually deactivates it)


#### Response

Returns the old, deactivated `Article-Object`

#### Errors

* ArticleNotFoundException


### GET /article/search

#### Description

Search by name or barcode

#### Example

```json
{
  "count": 5,
  "articles": [
    {
      "id": 2,
      "name": "Club Mate",
      "barcode": "13373243",
      "amount": 100,
      "active": true,
      "usageCount": 0,
      "precursor": null,
      "created": "2018-08-17 14:21:25"
    },
    {}, {}, {}
  ]
}
```

#### Request-Parameters

|  field  | datatype    | description                   |
|---------|-------------|-------------------------------|
| query   | string      | search by barcode or name     |
| barcode | string      | search explicitly by barcode  |
| limit   | integer     | max results (default 25)      |


#### Response

Returns a list of articles as a `Article-Object`


### GET /settings

#### Description

Returns the settings currently active.

#### Response

Returns the `Settings` from the config file but as JSON.

#### Errors

## Misc

### Pagination

With these two parameters, you can page through the result set:

```?offset=0&limit=25```

### User-Object

```json
{
  "id": 1,
  "name": "schinken",
  "active": true,
  "email": "foo@bar.de",
  "balance": 233,
  "created": "2018-08-17 16:20:57",
  "updated": "2018-08-17 16:22:41"
}
```

|  field  | datatype       | description                   |
|---------|----------------|-------------------------------|
| id      | integer        | user identifier               |
| name    | string         | username                      |
| active  | boolean        | If user is deactivated or not |
| email   | string or null | e-mail address (optional )    |
| balance | integer        | balance in cents              |
| created | datetime       | datetime of creating          |
| updated | datetime       | datetime of last transaction  |

### Transaction-Object

```json
{
  "id": 3,
  "user": {
    "id": 1,
    "name": "schinken",
    "active": true,
    "email": "foo@bar.de",
    "balance": 233,
    "created": "2018-08-17 16:20:57",
    "updated": "2018-08-17 16:22:41"
  },
  "quantity": 1,
  "article": null,
  "sender": null,
  "recipient": {
    "id": 1,
    "name": "schinken",
    "active": true,
    "email": "foo@bar.de",
    "balance": 233,
    "created": "2018-08-17 16:20:57",
    "updated": "2018-08-17 16:22:41"
  },
  "comment": null,
  "amount": 33,
  "deleted": false,
  "isDeletable": true,
  "created": "2018-08-17 16:22:41"
}
```

|  field       | datatype               | description                                                              |
|--------------|------------------------|--------------------------------------------------------------------------|
| id           | integer                | transaction identifier                                                   |
| user         | User-Object            |                                                                          |
| quantity     | integer or null        | Quantity of article if created with an article                           |
| article      | Article-Object or null | Contains an article-object if the transaction is created with an article |
| recipient    | User-Object or null    | Contains an user-object of the transaction recipient                     |
| sender       | User-Object or null    | Contains an user-object of the transaction sender                        |
| comment      | string or null         | comment (optional)                                                       |
| amount       | integer                | amount in cents                                                          |
| deleted      | bool                   | if transaction has been reverted                                         |
| isDeletable  | bool                   | if transaction can be reverted                                           |
| created      | datetime               | datetime of creation                                                     |

### Article-Object

```json
{
  "id": 2,
  "name": "Club Mate",
  "barcode": "13373243",
  "amount": 100,
  "active": true,
  "usageCount": 0,
  "precursor": null,
  "created": "2018-08-17 14:21:25"
}
```

|  field     | datatype               | description                            |
|------------|------------------------|----------------------------------------|
| id         | integer                | article identifier                     |
| name       | string                 | name of the article                    |
| barcode    | string                 | barcode                                |
| amount     | integer                | amount in cents                        |
| active     | boolean                | active/inactive                        |
| usageCount | integer                | usage count in transactions            |
| precursor  | Article-Object or null | links to the precursor article, if any |
| created    | datetime               | datetime of creation                   |


### Exception

```json
{
  "class": "App\\Exception\\UserNotFoundException",
  "code": 404,
  "message": "User 'schinken' not found"
}
```

Current possible exceptions are

| exception                            | http status code | message                                                                          |
|--------------------------------------|------------------|----------------------------------------------------------------------------------|
| AccountBalanceBoundaryException      | 400              | Transaction amount '30' exceeds upper account balance boundary '10' for user '1' |
| ArticleBarcodeAlreadyExistsException | 409              | Active article (42) with barcode '13374242' already exists.                      |
| ArticleNotFoundException             | 404              | Article '42' not found                                                           |
| ArticleInactiveException             | 400              | Article 'Club Mate' (42) is inactive                                             |
| ParameterInvalidException            | 400              | Parameter 'email' is invalid                                                     |
| ParameterMissingException            | 400              | Parameter 'name' is missing                                                      |
| ParameterNotFoundException           | 500              | Mandarory config value 'parameter.foo' is missing                                |
| TransactionBoundaryException         | 400              | Transaction amount '10' exceeds upper transaction boundary '3'                   |
| TransactionNotFoundException         | 404              | Transaction '42' not found for user '23'                                         |
| TransactionNotDeletableException     | 400              | Transaction '42' is not deleteable                                               |
| UserAlreadyExistsException           | 409              | User 'schinken' already exists                                                   |
| UserNotFoundException                | 404              | User 'schinken' not found                                                        |
