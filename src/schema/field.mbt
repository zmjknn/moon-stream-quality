// MoonBit Stream Quality Engine - Schema Field Module
// Copyright 2026 zmjknn
// Apache-2.0 License

///|
/// Field Type enum representing expected data types.
pub(all) enum FieldType {
  IntType
  DoubleType
  StringType
  BoolType
  TimestampType
  ArrayType(FieldType)
  MapType
  AnyType
} derive(Eq, Debug)

///|
/// Human readable string representation of FieldType.
pub fn FieldType::to_string(self : FieldType) -> String {
  match self {
    IntType => "Int"
    DoubleType => "Double"
    StringType => "String"
    BoolType => "Bool"
    TimestampType => "Timestamp"
    ArrayType(elem) => "Array<" + elem.to_string() + ">"
    MapType => "Map"
    AnyType => "Any"
  }
}

///|
/// Field definition containing name, type, nullability, and optional default.
pub(all) struct FieldDef {
  name : String
  field_type : FieldType
  nullable : Bool
  default_val : @core.Value?
  description : String
} derive(Eq, Debug)

///|
/// Creates a new FieldDef.
pub fn FieldDef::new(
  name : String,
  field_type : FieldType,
  nullable? : Bool = true,
  default_val? : @core.Value? = None,
  description? : String = "",
) -> FieldDef {
  { name, field_type, nullable, default_val, description }
}

///|
/// Checks if a Value matches this FieldDef specification.
pub fn FieldDef::validate_value(self : FieldDef, val : @core.Value) -> Bool {
  if val.is_null() {
    return self.nullable
  }
  match self.field_type {
    IntType => val.is_int()
    DoubleType => val.is_number()
    StringType => val.is_string()
    BoolType => val.is_bool()
    TimestampType => val.is_timestamp() || val.is_int()
    ArrayType(_) => val.is_array()
    MapType => val.is_map()
    AnyType => true
  }
}
