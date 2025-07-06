# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     AccessControl.Repo.insert!(%AccessControl.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

everyoneGroup =
  AccessControl.Repo.insert!(%AccessControl.Group{
    name: "Everyone"
  })

exclusiveGroup =
  AccessControl.Repo.insert!(%AccessControl.Group{
    name: "My Group"
  })

testUser1 =
  AccessControl.Repo.insert!(%AccessControl.User{
    first_name: "Foo",
    last_name: "Bar",
    username: "foobar"
  })

testUser2 =
  AccessControl.Repo.insert!(%AccessControl.User{
    first_name: "Fizz",
    last_name: "Buzz",
    username: "fizzbuzz"
  })

AccessControl.Repo.insert!(%AccessControl.UserGroup{
  user_id: testUser1.id,
  group_id: everyoneGroup.id
})

AccessControl.Repo.insert!(%AccessControl.UserGroup{
  user_id: testUser2.id,
  group_id: everyoneGroup.id
})

AccessControl.Repo.insert!(%AccessControl.UserGroup{
  user_id: testUser2.id,
  group_id: exclusiveGroup.id
})

testResource1 =
  AccessControl.Repo.insert!(%AccessControl.Resource{
    name: "resource1"
  })

testResource2 =
  AccessControl.Repo.insert!(%AccessControl.Resource{
    name: "resource2"
  })

testResource3 =
  AccessControl.Repo.insert!(%AccessControl.Resource{
    name: "resource3"
  })

AccessControl.Repo.insert!(%AccessControl.UserResource{
  user_id: testUser1.id,
  resource_id: testResource1.id
})

AccessControl.Repo.insert!(%AccessControl.GroupResource{
  group_id: everyoneGroup.id,
  resource_id: testResource2.id
})

AccessControl.Repo.insert!(%AccessControl.GroupResource{
  group_id: exclusiveGroup.id,
  resource_id: testResource3.id
})
