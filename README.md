# What is `SwiftPQ`?

`SwiftPQ` is a simple wrapper of [libpq](https://www.postgresql.org/docs/current/libpq.html) that is a C-API to PostgreSQL.
You can send query to PostgreSQL server with raw SQL, or in the *Swifty* way.

> [!WARNING]  
>
> UNDER DEVELOPMENT. ANY APIs MAY CHANGE IN ANY TIME.

# Requirements

* Swift >= 5.10
* libpq

# Usage

## First of all: Establish the connection.

### By UNIX Socket

```Swift
import PQ

let connection = try Connection(
  unixSocketDirectoryPath: "/var/run/postgresql",
  database: databaseName,
  user: databaseUserName,
  password: databasePassword
)
```

### Specifying domain

```Swift
import PQ

let connection = try Connection(
  host: .localhost,
  database: databaseName,
  user: databaseUserName,
  password: databasePassword
)
```


## Let's send queries!

You can see the implementations of commands in ["Commands.swift"](Sources/PQ/Commands.swift).

### CREATE TABLE

#### Raw SQL

```Swift
let result = try await connection.execute(.rawSQL("""
CREATE TABLE products (
  product_no integer,
  name text,
  price numeric
);
"""))
```

#### SQL with String Interpolation

```Swift
let result = try await connection.execute(.rawSQL("""
CREATE TABLE \(identifier: "my_products#1") (
  product_no integer,
  name text,
  price numeric
);
"""))
```

### Swifty way

```Swift
let result = try await connection.execute(
  .createTable(
    "myFavouriteProducts",
    columns: [
      .name("product_no", dataType: .integer),
      .name("name", dataType: .text),
      .name("price", dataType: .numeric),
    ],
    ifNotExists: true
  )
)
```

### DROP TABLE

#### Raw SQL

```Swift
let result = try await connection.execute(.rawSQL("DROP TABLE my_table;"))
```

#### SQL with String Interpolation

```Swift
let result = try await connection.execute(.rawSQL("DROP TABLE \(identifier: "my_table#1");"))
```

### Swifty way

```Swift
let result = try await connection.execute(.dropTable("my_old_table", ifExists: true))
```


# License

MIT License.  
See "LICENSE.txt" for more information.
