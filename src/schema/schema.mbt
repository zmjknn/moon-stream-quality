// MoonBit Stream Quality Engine - Schema Definition Module
// Copyright 2026 zmjknn
// Apache-2.0 License

/// Schema validation failure detail.
pub(all) struct SchemaValidationError {
  field_name : String
  expected_type : String
  actual_value : String
  reason : String
} derive(Eq, Debug)

/// Event Schema containing list of expected fields and strictness mode.
pub(all) struct Schema {
  schema_id : String
  fields : Map[String, FieldDef]
  strict_mode : Bool // If true, unknown fields fail validation
} derive(Eq, Debug)

/// Creates a new Schema.
pub fn Schema::new(
  schema_id : String,
  strict_mode~ : Bool = false
) -> Schema {
  { schema_id, fields: Map([]), strict_mode }
}

/// Adds a field definition to Schema.
pub fn Schema::add_field(self : Schema, field_def : FieldDef) -> Unit {
  self.fields.set(field_def.name, field_def)
}

/// Gets a field definition by name.
pub fn Schema::get_field(self : Schema, field_name : String) -> FieldDef? {
  self.fields.get(field_name)
}

/// Validates a StreamEvent against this Schema.
pub fn Schema::validate_event(
  self : Schema,
  event : @core.StreamEvent
) -> Array[SchemaValidationError] {
  let errors : Array[SchemaValidationError] = []

  // Check required fields & field types
  self.fields.each(fn(name, field_def) {
    match event.get(name) {
      Some(val) => {
        if !field_def.validate_value(val) {
          errors.push({
            field_name: name,
            expected_type: field_def.field_type.to_string(),
            actual_value: val.to_string(),
            reason: "Type mismatch or non-nullable field was null",
          })
        }
      }
      None => {
        if !field_def.nullable {
          errors.push({
            field_name: name,
            expected_type: field_def.field_type.to_string(),
            actual_value: "missing",
            reason: "Required non-nullable field is missing from event",
          })
        }
      }
    }
  })

  // Check strict mode for unknown fields
  if self.strict_mode {
    event.payload.each(fn(k, v) {
      match self.fields.get(k) {
        None => {
          errors.push({
            field_name: k,
            expected_type: "undefined",
            actual_value: v.to_string(),
            reason: "Unknown field in strict schema mode",
          })
        }
        Some(_) => ()
      }
    })
  }

  errors
}

/// Infers a Schema from an array of sample events.
pub fn infer_schema(schema_id : String, events : Array[@core.StreamEvent]) -> Schema {
  let schema = Schema::new(schema_id)
  let field_types : Map[String, FieldType] = Map([])
  let field_nullability : Map[String, Bool] = Map([])
  let field_counts : Map[String, Int] = Map([])

  let total_events = events.length()

  for i = 0; i < events.length(); i = i + 1 {
    let event = events[i]
    event.payload.each(fn(k, v) {
      let cnt = match field_counts.get(k) {
        Some(c) => c + 1
        None => 1
      }
      field_counts.set(k, cnt)

      let inferred_type = match v {
        Int(_) => FieldType::IntType
        Double(_) => FieldType::DoubleType
        String(_) => FieldType::StringType
        Bool(_) => FieldType::BoolType
        Timestamp(_) => FieldType::TimestampType
        Array(_) => FieldType::ArrayType(FieldType::AnyType)
        Map(_) => FieldType::MapType
        Bytes(_) => FieldType::AnyType
        Null => FieldType::AnyType
      }

      if v.is_null() {
        field_nullability.set(k, true)
      } else {
        match field_types.get(k) {
          None => field_types.set(k, inferred_type)
          Some(existing) => {
            if existing != inferred_type && existing != FieldType::AnyType {
              field_types.set(k, FieldType::AnyType)
            }
          }
        }
      }
    })
  }

  field_types.each(fn(name, ftype) {
    let explicitly_null = match field_nullability.get(name) {
      Some(b) => b
      None => false
    }
    let appearance_count = match field_counts.get(name) {
      Some(c) => c
      None => 0
    }
    let nullable = explicitly_null || appearance_count < total_events
    schema.add_field(FieldDef::new(name, ftype, nullable~))
  })

  schema
}
