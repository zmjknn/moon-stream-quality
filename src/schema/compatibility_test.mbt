// MoonBit Stream Quality Engine - Schema Compatibility Tests
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
fn schema_with_id(nullable : Bool) -> Schema {
  let schema = Schema::new("orders")
  schema.add_field(FieldDef::new("id", FieldType::IntType, nullable~))
  schema
}

///|
test "identical schemas report an unchanged compatible diff" {
  let old_schema = schema_with_id(false)
  let new_schema = schema_with_id(false)
  let diff = compare_schemas(old_schema, new_schema, Strict)
  assert_eq(diff.compatible, true)
  assert_eq(diff.changes, [Unchanged])
}

///|
test "optional additions are backward compatible" {
  let old_schema = schema_with_id(false)
  let new_schema = schema_with_id(false)
  new_schema.add_field(FieldDef::new("region", FieldType::StringType))
  let diff = compare_schemas(old_schema, new_schema, BackwardCompatible)
  assert_eq(diff.compatible, true)
  assert_eq(diff.changes, [AddedOptional("region")])
}

///|
test "required additions are rejected by strict and backward modes" {
  let old_schema = schema_with_id(false)
  let new_schema = schema_with_id(false)
  new_schema.add_field(
    FieldDef::new("created_at", FieldType::TimestampType, nullable=false),
  )
  let strict_diff = compare_schemas(old_schema, new_schema, Strict)
  let backward_diff = compare_schemas(
    old_schema,
    new_schema,
    BackwardCompatible,
  )
  assert_eq(strict_diff.compatible, false)
  assert_eq(backward_diff.compatible, false)
  assert_eq(strict_diff.changes, [AddedRequired("created_at")])
}

///|
test "field removal differs between backward and forward modes" {
  let old_schema = schema_with_id(false)
  old_schema.add_field(FieldDef::new("legacy", FieldType::StringType))
  let new_schema = schema_with_id(false)
  let backward_diff = compare_schemas(
    old_schema,
    new_schema,
    BackwardCompatible,
  )
  let forward_diff = compare_schemas(old_schema, new_schema, ForwardCompatible)
  assert_eq(backward_diff.compatible, true)
  assert_eq(forward_diff.compatible, false)
  assert_eq(backward_diff.changes, [Removed("legacy")])
}

///|
test "type changes are always visible and incompatible" {
  let old_schema = schema_with_id(false)
  let new_schema = Schema::new("orders")
  new_schema.add_field(
    FieldDef::new("id", FieldType::StringType, nullable=false),
  )
  let diff = compare_schemas(old_schema, new_schema, ForwardCompatible)
  assert_eq(diff.compatible, false)
  assert_eq(diff.changes, [TypeChanged("id", "Int", "String")])
}

///|
test "defaults are applied only to missing fields" {
  let schema = Schema::new("orders")
  schema.add_field(
    FieldDef::new(
      "region",
      FieldType::StringType,
      default_val=Some(@core.Value::String("unknown")),
    ),
  )
  schema.add_field(
    FieldDef::new(
      "attempt",
      FieldType::IntType,
      default_val=Some(@core.Value::Int(1L)),
    ),
  )
  let payload : Map[String, @core.Value] = Map([])
  payload.set("attempt", @core.Value::Int(3L))
  let event = @core.StreamEvent::new("e1", 100L, payload~)
  assert_eq(apply_schema_defaults(schema, event), 1)
  assert_eq(event.get_string("region"), Some("unknown"))
  assert_eq(event.get_int("attempt"), Some(3L))
}

///|
test "missing defaults do not mutate the event" {
  let schema = Schema::new("orders")
  schema.add_field(FieldDef::new("region", FieldType::StringType))
  let event = @core.StreamEvent::new("e2", 100L)
  assert_eq(apply_schema_defaults(schema, event), 0)
  assert_eq(event.has_field("region"), false)
}
