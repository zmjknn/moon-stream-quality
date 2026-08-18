// MoonBit Stream Quality Engine - Schema Compatibility Boundary Coverage
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
test "type changes are incompatible in every supported mode" {
  let old_schema = Schema::new("types")
  old_schema.add_field(FieldDef::new("value", FieldType::IntType))
  let new_schema = Schema::new("types")
  new_schema.add_field(FieldDef::new("value", FieldType::StringType))
  for
    mode in [
      CompatibilityMode::Strict,
      CompatibilityMode::BackwardCompatible,
      CompatibilityMode::ForwardCompatible,
    ] {
    let diff = compare_schemas(old_schema, new_schema, mode)
    assert_eq(diff.compatible, false)
    assert_eq(diff.changes.length(), 1)
  }
}

///|
test "backward mode accepts an optional field with a default" {
  let old_schema = Schema::new("defaults")
  let new_schema = Schema::new("defaults")
  new_schema.add_field(
    FieldDef::new(
      "region",
      FieldType::StringType,
      nullable=false,
      default_val=Some(@core.Value::String("cn")),
    ),
  )
  let diff = compare_schemas(
    old_schema,
    new_schema,
    CompatibilityMode::BackwardCompatible,
  )
  assert_eq(diff.compatible, true)
  assert_eq(diff.changes, [AddedOptional("region")])
}

///|
test "forward mode rejects a removed field" {
  let old_schema = Schema::new("removed")
  old_schema.add_field(FieldDef::new("legacy", FieldType::BoolType))
  let new_schema = Schema::new("removed")
  let diff = compare_schemas(old_schema, new_schema, ForwardCompatible)
  assert_eq(diff.compatible, false)
  assert_eq(diff.changes, [Removed("legacy")])
}

///|
test "defaults apply only to absent fields and count exactly" {
  let schema = Schema::new("apply")
  schema.add_field(
    FieldDef::new(
      "a",
      FieldType::IntType,
      default_val=Some(@core.Value::Int(1L)),
    ),
  )
  schema.add_field(
    FieldDef::new(
      "b",
      FieldType::StringType,
      default_val=Some(@core.Value::String("x")),
    ),
  )
  let payload : Map[String, @core.Value] = Map([])
  payload.set("a", @core.Value::Int(9L))
  let event = @core.StreamEvent::new("defaults", 1L, payload~)
  assert_eq(apply_schema_defaults(schema, event), 1)
  assert_eq(event.get_int("a"), Some(9L))
  assert_eq(event.get_string("b"), Some("x"))
}

///|
test "same field names with equal definitions are unchanged" {
  let old_schema = Schema::new("same")
  old_schema.add_field(FieldDef::new("id", FieldType::StringType))
  let new_schema = Schema::new("same")
  new_schema.add_field(FieldDef::new("id", FieldType::StringType))
  let diff = compare_schemas(old_schema, new_schema, Strict)
  assert_eq(diff.compatible, true)
  assert_eq(diff.changes, [Unchanged])
}

///|
test "multiple changes preserve deterministic field traversal" {
  let old_schema = Schema::new("ordered")
  old_schema.add_field(FieldDef::new("old", FieldType::IntType))
  let new_schema = Schema::new("ordered")
  new_schema.add_field(FieldDef::new("old", FieldType::StringType))
  new_schema.add_field(FieldDef::new("new", FieldType::BoolType))
  let diff = compare_schemas(old_schema, new_schema, BackwardCompatible)
  assert_eq(diff.changes.length(), 2)
  assert_eq(diff.compatible, false)
}
