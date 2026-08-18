// MoonBit Stream Quality Engine - Schema Edge Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "strict mode rejects an optional field addition" {
  let old_schema = Schema::new("edge")
  let new_schema = Schema::new("edge")
  new_schema.add_field(FieldDef::new("optional", FieldType::StringType))
  let diff = compare_schemas(old_schema, new_schema, Strict)
  assert_eq(diff.compatible, false)
  assert_eq(diff.changes, [AddedOptional("optional")])
}

///|
test "forward mode allows a required field addition" {
  let old_schema = Schema::new("edge")
  let new_schema = Schema::new("edge")
  new_schema.add_field(
    FieldDef::new("required", FieldType::IntType, nullable=false),
  )
  let diff = compare_schemas(old_schema, new_schema, ForwardCompatible)
  assert_eq(diff.compatible, true)
  assert_eq(diff.changes, [AddedRequired("required")])
}

///|
test "nullability change is visible and incompatible" {
  let old_schema = Schema::new("edge")
  old_schema.add_field(FieldDef::new("id", FieldType::IntType))
  let new_schema = Schema::new("edge")
  new_schema.add_field(FieldDef::new("id", FieldType::IntType, nullable=false))
  let diff = compare_schemas(old_schema, new_schema, BackwardCompatible)
  assert_eq(diff.compatible, false)
  assert_eq(diff.changes, [NullabilityChanged("id", true, false)])
}

///|
test "default does not overwrite an explicit null field" {
  let schema = Schema::new("edge")
  schema.add_field(
    FieldDef::new(
      "region",
      FieldType::StringType,
      default_val=Some(@core.Value::String("default")),
    ),
  )
  let payload : Map[String, @core.Value] = Map([])
  payload.set("region", @core.Value::Null)
  let event = @core.StreamEvent::new("e", 1L, payload~)
  assert_eq(apply_schema_defaults(schema, event), 0)
  assert_eq(event.contains_key("region"), false)
  assert_eq(event.has_field("region"), true)
}

///|
test "empty schema comparison is stable" {
  let old_schema = Schema::new("empty")
  let new_schema = Schema::new("empty")
  let diff = compare_schemas(old_schema, new_schema, ForwardCompatible)
  assert_eq(diff.compatible, true)
  assert_eq(diff.changes, [Unchanged])
  assert_eq(diff.defaults_applied, 0)
}

///|
test "default values retain their declared dynamic type" {
  let schema = Schema::new("typed")
  schema.add_field(
    FieldDef::new(
      "attempt",
      FieldType::IntType,
      default_val=Some(@core.Value::Int(2L)),
    ),
  )
  let event = @core.StreamEvent::new("typed-event", 1L)
  assert_eq(apply_schema_defaults(schema, event), 1)
  assert_eq(event.get_int("attempt"), Some(2L))
}
