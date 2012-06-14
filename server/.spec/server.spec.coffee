describe "dummy test", ->
  it "true should be true", ->
    expect(true).toBe true

describe "Repository test", ->
  db = new Repository("test")
  it "should be able to add and find", ->
    test.add ("john doe")
    test.find("john doe").toBe "john doe"