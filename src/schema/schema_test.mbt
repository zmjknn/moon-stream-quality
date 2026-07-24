// MoonBit Stream Quality Engine - Schema Package Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "schema field validation" {
  let schema = Schema::new("user_schema", strict_mode=true)
  schema.add_field(FieldDef::new("id", FieldType::IntType, nullable=false))
  schema.add_field(FieldDef::new("name", FieldType::StringType, nullable=false))
  schema.add_field(FieldDef::new("age", FieldType::IntType, nullable=true))

  let payload : Map[String, @core.Value] = Map([])
  payload.set("id", @core.Value::Int(42L))
  payload.set("name", @core.Value::String("Bob"))
  payload.set("age", @core.Value::Null)

  let valid_event = @core.StreamEvent::new("e1", 1000L, payload~)
  let errs1 = schema.validate_event(valid_event)
  assert_eq(errs1.length(), 0)

  // Missing required field
  let invalid_payload : Map[String, @core.Value] = Map([])
  invalid_payload.set("name", @core.Value::String("Alice"))
  let invalid_event = @core.StreamEvent::new(
    "e2",
    1001L,
    payload=invalid_payload,
  )
  let errs2 = schema.validate_event(invalid_event)
  assert_eq(errs2.length(), 1)
  assert_eq(errs2[0].field_name, "id")
}

///|
test "schema inference" {
  let p1 : Map[String, @core.Value] = Map([])
  p1.set("device_id", @core.Value::String("sensor-01"))
  p1.set("temp", @core.Value::Double(25.4))

  let p2 : Map[String, @core.Value] = Map([])
  p2.set("device_id", @core.Value::String("sensor-02"))
  p2.set("temp", @core.Value::Double(26.1))
  p2.set("humidity", @core.Value::Double(60.0))

  let events = [
    @core.StreamEvent::new("ev1", 100L, payload=p1),
    @core.StreamEvent::new("ev2", 101L, payload=p2),
  ]

  let inferred = infer_schema("sensor_schema", events)
  assert_eq(
    inferred.get_field("device_id").unwrap().field_type,
    FieldType::StringType,
  )
  assert_eq(
    inferred.get_field("temp").unwrap().field_type,
    FieldType::DoubleType,
  )
  assert_eq(
    inferred.get_field("humidity").unwrap().field_type,
    FieldType::DoubleType,
  )
  assert_eq(inferred.get_field("humidity").unwrap().nullable, true)
}
