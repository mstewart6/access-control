# AccessControl

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: <https://www.phoenixframework.org/>
* Guides: <https://hexdocs.pm/phoenix/overview.html>
* Docs: <https://hexdocs.pm/phoenix>
* Forum: <https://elixirforum.com/c/phoenix-forum>
* Source: <https://github.com/phoenixframework/phoenix>

## Requirements

* [ASDF](https://asdf-vm.com/) version manager
  
  Or install the following versions manually:
  * Erlang 1.18.4
  * Elixir 28.0.1
* Postgres

## Setting up

1. `asdf install` to get elixir and erlang
1. `mix setup`
    * Fetches and installs depenencies
    * Migrates database
    * Seeds database
        Seed data contains `Everyone` group, an extra group `My Group`, 2 users, and
        some sharing already set up across 3 resources
1. Run server with `mix phx.server`
1. Access API-only application at <http://localhost:4000> (recommended via Postman
    or other JSON client)

## Routes

### Users

1. Create User `POST to /users`
    Request Body:

    ```json
    {
      "user": {
        "first_name": "firstname",
        "last_name": "lastname",
        "username": "username" // This field is unique
      }
    }
    ```

    Note: Will automatically be added to `Everyone` group

1. List Users `GET to /users`
1. List all Resources for User `GET to /user/:user_id/resources`
1. List all Users with Resource counts `GET to /users/with-resource-count`

### Groups

1. Create Group `POST to /groups`
    Request Body:

    ```json
    {
      "group": {
        "name": "groupname" // This field is unique
      }
    }
    ```

1. List Groups `GET to /groups`
1. Add User to Group `POST to /groups/:group_id`
    Request Body:

    ```json
    {
      "user_id": "UUID"
    }
    ```

1. Remove User from Group `DELETE to /groups/:group_id/users/:user_id`
    Note: Will not remove user from the `Everyone` group

### Resources

1. Create Resource `POST to /resources`
    Request Body:

    ```json
    {
      "resource": {
        "name": "resourcename" // This field is unique
      }
    }
    ```

1. List Resources `GET to /resources`

1. Share Resource to Group `POST to /resource/:resource_id/share-group`
    Request Body:

    ```json
    {
      "group_id": "UUID"
    }
    ```

1. Share Resource to User `POST to /resource/:resource_id/share-user`
    Request Body:

    ```json
    {
      "user_id": "UUID"
    }
    ```

1. Unshare Resource from Group `DELETE to /resource/:resource_id/group/:group_id`
1. Unshare Resource from User `DELETE to /resource/:resource_id/user/:user_id`
1. List all Users for Resource `GET to /resource/:resource_id/access-list`
1. Aggregation for User count per Resource `GET to /resources/with-user-count`

## Known Issues

1. Error handling/rendering
    This is mostly ignored. The database has the proper constraints, code just
    doesn't gracefully handle the responses, so throws 500s for non-happy path calls.
1. Testing
    There aren't any tests
1. Detection of `Everyone` group to ensure that it exists when creating users.
    It's provided in the dev seed, but no other envs, and seeds aren't sufficient
    for guarantees.
1. Everyone group lookup should be in one place (group.ex)
1. No soft delete and auditing beyond create/update columns
1. Pagination for large data sets
1. Distributed queries for large data sets
1. Containerization and other productionization
1. Access control
1. Linting and some inconsistent code style
1. User and Resource counting functions do not use DB-optimized queries, instead
    doing the collection in-app
1. Looking up individual resource and user disabled due to collision with
    aggregation endpoints

## Schema Design

* Standard relational DB with join tables for User <> Group, User <> Resource,
  Group <> Resource
* Join tables are used exclusively for relationships
* Subqueries utilized to optimize selection logic for the joins
* Unique foreign key indices to prevent duplicate entries for User in group, User
  direct resource share, Group resource share
* Global sharing managed through automatic `Everyone` group membership on user creation
* UUID keys for non-join tables
* Resources can be shared with individuals and groups separately (these could be
  returned separately if necessary)
