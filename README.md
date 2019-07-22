# Banking

## Environment

### Generate docker files and required enviroment variables for both dev and production environments
```bash
$ cd devops
$ ./build_files.py
```
The output this command is print of generation files

```bash
$ cd dev
$ docker-compose up -d
$ docker-compose exec app bash
```

### Runing Test
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

**POST** `localhost:4000/api/accounts`

Parameters Example:
```json
{
  "name": "some name",
  "email": "email@test.com"
}
```
**GET** `localhost:4000/api/accounts`
Return the account list

Dependencies
---------------------------
 * Docker
 * docker-compose
 * Python 2/3