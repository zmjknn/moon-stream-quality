// MoonBit Stream Quality Engine - Schema Evolution Compatibility
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Compatibility policy used when an event producer changes its schema.
pub(all) enum CompatibilityMode {
  Strict
  BackwardCompatible
  ForwardCompatible
} derive(Eq, Debug)

///|
/// A single observable schema change.
pub(all) enum SchemaChange {
  AddedOptional(String)
  AddedRequired(String)
  Removed(String)
  TypeChanged(String, String, String)
  NullabilityChanged(String, Bool, Bool)
  Unchanged
} derive(Eq, Debug)

///|
/// A deterministic summary of schema changes and compatibility.
pub(all) struct SchemaDiff {
  compatible : Bool
  changes : Array[SchemaChange]
  defaults_applied : Int
} derive(Eq, Debug)

///|
fn change_is_compatible(
  mode : CompatibilityMode,
  change : SchemaChange,
) -> Bool {
  match (mode, change) {
    (_, Unchanged) => true
    (Strict, _) => false
    (BackwardCompatible, AddedOptional(_)) => true
    (BackwardCompatible, Removed(_)) => true
    (ForwardCompatible, AddedOptional(_)) => true
    (ForwardCompatible, AddedRequired(_)) => true
    (_, _) => false
  }
}

///|
fn compare_existing_field(
  name : String,
  old_field : FieldDef,
  new_field : FieldDef,
) -> SchemaChange {
  if old_field.field_type != new_field.field_type {
    TypeChanged(
      name,
      old_field.field_type.to_string(),
      new_field.field_type.to_string(),
    )
  } else if old_field.nullable != new_field.nullable {
    NullabilityChanged(name, old_field.nullable, new_field.nullable)
  } else {
    Unchanged
  }
}

///|
fn compare_added_field(name : String, field : FieldDef) -> SchemaChange {
  match field.default_val {
    Some(_) => AddedOptional(name)
    None =>
      if field.nullable {
        AddedOptional(name)
      } else {
        AddedRequired(name)
      }
  }
}

///|
/// Compares two schemas without coercing incompatible field values.
pub fn compare_schemas(
  old_schema : Schema,
  new_schema : Schema,
  mode : CompatibilityMode,
) -> SchemaDiff {
  let changes : Array[SchemaChange] = []
  old_schema.fields.each(fn(name, old_field) {
    match new_schema.fields.get(name) {
      Some(new_field) => {
        let change = compare_existing_field(name, old_field, new_field)
        match change {
          Unchanged => ()
          _ => changes.push(change)
        }
      }
      None => changes.push(Removed(name))
    }
  })
  new_schema.fields.each(fn(name, new_field) {
    match old_schema.fields.get(name) {
      Some(_) => ()
      None => changes.push(compare_added_field(name, new_field))
    }
  })
  if changes.length() == 0 {
    changes.push(Unchanged)
  }
  let mut compatible = true
  for change in changes {
    if !change_is_compatible(mode, change) {
      compatible = false
    }
  }
  { compatible, changes, defaults_applied: 0 }
}

///|
/// Applies declared defaults to missing fields and returns the number applied.
pub fn apply_schema_defaults(schema : Schema, event : @core.StreamEvent) -> Int {
  let mut applied = 0
  schema.fields.each(fn(name, field) {
    match event.get(name) {
      Some(_) => ()
      None =>
        match field.default_val {
          Some(default_value) => {
            event.set(name, default_value)
            applied = applied + 1
          }
          None => ()
        }
    }
  })
  applied
}
