# GoustoApiTask

To start application:

  * Install Elixir ( http://elixir-lang.org/install.html )
  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `CSV_DATA_FILE=data/recipe-data.csv mix phoenix.server` - loads CSV data on first request

Now you can visit [`localhost:4000/api/recipes`](http://localhost:4000/api/recipes) from your browser.

## About

This is implementation of Gousto API Task in Elixir. Here is extraction of specification for the task:

### Specification

Your API must offer the following operations:

  * Fetch a recipe by id
  * Fetch all recipes for a specific cuisine (should paginate)
  * Rate an existing recipe between 1 and 5
  * Update an existing recipe
  * Store a new recipe

Don’t include any client code e.g. HTML

The service should provide a set of RESTful JSON based routes

Another non-functional requirements:

  * The service must be built using a modern web application framework
  * The code should be ‘production ready’ and maintainable
  * The service should use the accompanying CSV as the primary data source, which can be loaded into memory (please don't use a
  database, though SQLite would be acceptable). Feel free to generate additional test data based on the same scheme if it helps.


## Implementation consideration

### Language

I choosed Elixir language. Elixir is robust functional, compiled language that has been inspired by Ruby but with goal to provide nice and easy to write and read syntax without sacrificing performance, compile time checks and robust concurrency model.

### Framework

As specification required application has to be built in modern web framework - so I could not use micro-frameworks like [Trot](https://github.com/hexedpackets/trot). I choosed then Phoenix. Phoenix is MVC framework on top of Elixir. It has built in support for JSON API, WebSockets and is in active development with growing comunity of developers. Phoenix is meant to be "Ruby on Rails" for Elixir.

I assesed also [Relax](https://github.com/AgilionApps/relax). Relax is framework build around JSON-API specification, leveraging it and making development of APIs following this specification easy. However it doesn't seem maintained or actively developing and on it's own GitHub page there is lot of features not done in TODO.

### Database

Specification denies using of full-fledged database servers. So initialy I wanted to use SQLite as backend for the `Ecto` library that is tightly integrated within Phoenix. Unfortunatelly SQLite backend for Ecto is currently not maintained and it's latest version 0.11.0 is not compatible with the latest version Ecto that Phoenix is using.

This led me to need of implementing my own in memory storage layer. In Elixir there is not such thing as global variables, which makes it's robust core, but complicates pressumably simple tasks like storing data globally in the application memory.

I implemented the layer in [/lib/gousto_api_task/in_memory_store.ex]() using Erlang's OTP mechanism and `GenServer` library. The storage is implemented as simple linked list of records. Lookup and update operations are in `O(n)`, insert is `O(1)`.

On top of that store I implemented wrapper in [/lib/gousto_api_task/repo.ex]() that mimics original Ecto interface to some degree, which should make it easier for eventual switch to the Ecto backend in the future.

### API format

Specification requires to build API in "RESTful JSON" way. [JSON-API specification](http://jsonapi.org) provides very well curated and industry accepted rules for building such API. I choosed to follow it in my application.

The public specification should besides avoiding common mistakes in JSON API design also provide libraries that could speed up and help development of such APIs. For Ruby or Node.js these libraries exists and are very well maintained with active community of developers. Unfortunatelly community around Elixir as it is still non-mainstream platform doesn't provide such libraries that would be mature enough.

[JA_Serializer](https://github.com/AgilionApps/ja_serializer) aims to care only about the rendering part of JSON-API responses. Small and focused, but unfortuntally doesn't provide support for custom `link` fields, which are needed for pagination functionality that is required in specification for this application.

[JSONAPI](https://github.com/jeregrine/jsonapi) is more complex and tries to handle the request from transforming filtering and pagination parameters to Ecto queries and rendering the JSON-API response with subset of fields if requested. Altought it has documented support for pagination links, I was not successful to use it. Moreover absence of Ecto layer in my application doesn't allow me to use not even for the query parsing.

In the end I resorted to simple straightworfard rendering of JSON-API respons directly via Phoenix's views. Rendered responses are hence JSON-API compliant - both for successful request and for response containing errors.

My implementation supports JSON-API filters via `filter[field]=value` query parameters and pagination using `page[offset]` and `page[limit]` parameters. This satisfies the Task requirements.

Other features required by JSON-API specification as sorting and sparse fieldset definition are not supported in my implementation as it would be over requirements of the Task.

### Slug

Given data set contains besides integral ID for the records also slugs identifiers. The Recipe API implements automatic slug generation from the Recipe `title` if the `slug` field is not present. Generator converts title to downcase letters and replaces all non-alphanumeric characters to dashes. Storage layer ensures then that slug is unique in the set of records.

Slug name then can be used as supplement for ID in the API endpoint, which allows to fetch recipe from the recipe detail webpage without need to first translate the slug to ID.

### CSV data

As required in Task CSV file should be used for data source. This behavior is implemented using Plug mechanism in Phoenix framework that runs given function as part of pipeline for each HTTP request.

If the environmental variable `CSV_DATA_FILE` is present, this function loads recipes from CSV file to the in memory store before first request is processed in controller.

### Authentication

As not required by Task, authentication is not implemented in any way in the application. However for actual production deployment write actions (create and update) should require authorization.

[JSON Web Tokens](https://jwt.io/) is modern approach for authenticating HTTP APIs that are split accross multiple applications, using signed data tokens including state or other information about user. It may include ACL lists, user IDs etc that are signed by authentication service and then can be used by other services without need of contacting database for each request.

### Tests

Built-in part of Phoenix framework is testing suit allowing to write tests for various parts of the application including integration tests of API requests.

Tests I implemented cover all the specified API endpoints and actions - for both valid and invalid requests.

## API Documentation

All API endpoint uses JSONAPI specification. All requests MUST use content type and accepts header `application/vnd.api+json`.

### Recipes

`GET /api/recipes`

Fetches all recipes

Query parameters:

  * `filter` - array of key-value fields to filter records only that matches it. Example: `filter[recipe_cuisine]=asian` retrieves only asian cuisine recipies
  * `page[offset]` - specifies number of records to skip from beginning. Default 0
  * `page[limit]` - speficies maximum number of records per response. Default 50

Responses:

  * 200 Ok - Successfuly fetched and returned in  response body

Example Response:

```json
200 OK

{
  "links":{
    "prev":null,
    "next":null,
    "last":"http://localhost:4000/api/recipes?page[limit]=50&page[offset]=0",
    "first":"http://localhost:4000/api/recipes?page[limit]=50&page[offset]=0"
  },
  "data":[{
    "type":"recipes",
    "id":"1",
    "attributes":{
        "updated_at":"2015-06-30T17:58:00Z",
        "created_at":"2015-06-30T17:58:00Z",
        "title":"Sweet Chilli and Lime Beef on a Crunchy Fresh Noodle Salad",
        "slug":"sweet-chilli-and-lime-beef-on-a-crunchy-fresh-noodle-salad",
        "short_title":"",
        ...
    }
  }]
}
```

`GET /api/recipes/:id`

Fetches recipe with given ID of slug

  * 200 Ok - recipe with given ID found and is included in the response
  * 404 Not found - given ID or slug doesn't matches with any record

Example Response - Recipe exists:

```json
200 OK

{
  "data":{
    "type":"recipes",
    "id":"1",
    "attributes":{
        "updated_at":"2015-06-30T17:58:00Z",
        "created_at":"2015-06-30T17:58:00Z",
        "title":"Sweet Chilli and Lime Beef on a Crunchy Fresh Noodle Salad",
        "slug":"sweet-chilli-and-lime-beef-on-a-crunchy-fresh-noodle-salad",
        "short_title":"",
        ...
    }
  }
}
```

Example Response - Not found:

```
404 Not found
```

`POST /api/recipes`

Create recipe from JSONAPI attributes

Attributes:
  * name - required non blank
  * slug - optional. if blank will be generated from name. if set, it must be unique
  * ...

Response:
  * 201 Created - succssfully created, contains JSONAPI response of new recipe
  * 400 Bad request - set non existing fields, wrong type, etc.
  * 422 Unprocessable Entity - record data validations are violated - empty name, slug already used etc.

Example Request:
```json
POST /api/recipes

{
  "data":{
    "type":"recipes",
    "attributes":{
        "title":"Sweet Chilli and Lime Beef on a Crunchy Fresh Noodle Salad",
        "slug":"sweet-chilli-and-lime-beef-on-a-crunchy-fresh-noodle-salad",
        "short_title":"",
        ...
    }
  }
}
```

Example Response - 201:

```json
200 OK

{
  "data":{
    "type":"recipes",
    "id":"1",
    "attributes":{
        "updated_at":"2015-06-30T17:58:00Z",
        "created_at":"2015-06-30T17:58:00Z",
        "title":"Sweet Chilli and Lime Beef on a Crunchy Fresh Noodle Salad",
        "slug":"sweet-chilli-and-lime-beef-on-a-crunchy-fresh-noodle-salad",
        "short_title":"",
        ...
    }
  }
}
```

Example Response - 422:
```json
{
  "errors": [{
    "title": "Cannot be blank",
    "source": "/data/attributes/title"
  }]
}
```

`PUT /api/recipes/:id`

Updates recipe with given ID or slug.

Attributes:

  * name - recipe name
  * slug - cannot be updated
  * ...

Responses:

  * 200 Ok - Succsfully updated
  * 422 Unprocessable entity - new values violates record validations. no changes has been saved

Example Request:
```json
PUT /api/recipes/1

{
  "data":{
    "type":"recipes",
    "id": 1
    "attributes":{
        "title":"Sweet Chilli and Lime Beef on a Crunchy Fresh Noodle Salad",
        "short_title":"Noodle Chilli con Carne",
        ...
    }
  }
}
```

Example Response - 200:

```json
200 OK

{
  "data":{
    "type":"recipes",
    "id":"1",
    "attributes":{
        "updated_at":"2015-06-30T17:58:00Z",
        "created_at":"2015-06-30T18:23:00Z",
        "title":"Sweet Chilli and Lime Beef on a Crunchy Fresh Noodle Salad",
        "slug":"sweet-chilli-and-lime-beef-on-a-crunchy-fresh-noodle-salad",
        "short_title":"Noodle Chilli con Carne",
        ...
    }
  }
}
```

### Recipe rating

`GET /api/recipe/:id/ratings`

Fetch all ratings of given recipe (only numerical ID)

`POST /api/recipe/:id/ratings`

Rate given recipe (only numerical ID)

Attributes:

  * rating - value of rating, allowed only integer numbers from 1 to 5.

Repsonse:

  * 201 Created - successfully rated
  * 404 Not found - recipe with given ID doesn't exist
  * 422 Unprocessable entity - invalid attributes, check the response for erros

Example Request:
```json
POST /api/recipes/1/ratings

{
  "data":{
    "type":"recipe_ratings",
    "attributes":{
        "rating": 5
    }
  }
}
```

Example Response - 201:

```json
201 Created

{
  "data":{
    "type":"recipe_ratings",
    "id":"1",
    "attributes":{
        "updated_at":"2015-06-30T17:58:00Z",
        "created_at":"2015-06-30T17:58:00Z",
        "rating":5
    }
  }
}
```

Example Response - 422:
```json
{
  "errors": [{
    "title": "Rating have to be integer number between 1 and 5 inclusive",
    "source": "/data/attributes/rating"
  }]
}
```

## Testing

Run tests with

  * Install dependencies `mix deps.get`
  * Run tests `mix test`

## Author

Lukas Dolezal (lukas@dolezalu.cz)

LinkedIn: https://www.linkedin.com/in/lukasdolezal
