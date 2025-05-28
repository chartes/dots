(: documentation: https://docs.basex.org/main/Unit_Functions :)

declare variable $db := 'unit-test';

declare %updating %unit:before-module function local:before-all-tests() {
  db:create($db)
};

declare %updating %unit:before function local:before() {
  db:add($db, <a/>, 'a.xml')
};

declare %unit:test function local:test() {
  unit:assert(db:exists($db)),
  unit:assert(count(db:get($db)) = 1)
};

declare %unit:test("expected", "db:open") function local:error() {
  unit:assert(db:get('unknown'))
};

declare %unit:test function local:try() {
  try {
    db:get('unknown')
  } catch db:open (: or: db:* :){
    (: expected result :)
  }
};

declare %unit:test function local:try2() {
  try {
    unit:assert(empty(db:get($db)))
  } catch db:open (: or: db:* :){
    unit:fail('Database should exist')
  }
};

declare %updating %unit:after-module function local:after-all-tests() {
  db:drop($db)
};

()
