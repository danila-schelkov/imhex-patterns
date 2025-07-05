
import std.limits;

struct VTable {
    u16 vtable_size;  // starting from here
    u16 table_data_size;
    u16 field_count = (vtable_size - 4) / 2;
    u16 field_offsets[field_count];
};

struct RootTable {
    u32 vtable_offset_offset; 
    s32 vtable_offset @ addressof(vtable_offset_offset) + vtable_offset_offset;
    VTable vtable @ addressof(vtable_offset_offset) + vtable_offset_offset - vtable_offset;
};

fn get_field_address(ref RootTable table, u32 field_index, u64 default_offset) {
    if (table.vtable.field_count <= field_index) {
        return std::limits::u64_max();
    }

    u16 field_offset = table.vtable.field_offsets[field_index];
    if (field_offset == 0) {
        return std::limits::u64_max();
    }

    return addressof(table.vtable_offset) + field_offset;
};

struct Field<Type, auto Table, auto Index, auto DefaultValue> {
    bool has_default = DefaultValue != std::limits::u64_max();

    u64 field_address = get_field_address(Table, Index, DefaultValue);
    if (field_address != std::limits::u64_max()) {
        Type value @ field_address;
    } else if (has_default) {
        Type value = DefaultValue;
    }
} [[format_read("format_field_read")]];

fn format_field_read(ref auto field) {
    if (field.field_address == std::limits::u64_max() && !field.has_default) {
        return "undefined";
    }

    return std::format("{}", field.value);
};

using Optional<Type, auto Table, auto Index> = Field<Type, Table, Index, std::limits::u64_max()>;

struct Ptr<Type> {
    u32 offset;
    Type value @ addressof(offset) + offset;
} [[format_read("format_ptr_read")]];

fn format_ptr_read(ref Ptr<auto> ptr) {
    return ptr.value;
};

struct FieldPtr<Type, auto Table, auto Index, auto DefaultValue> {
    u64 field_address = get_field_address(Table, Index, DefaultValue);
    if (field_address != std::limits::u64_max()) {
        Ptr<Type> value @ field_address [[inline]];
    }
};

using OptionalPtr<Type, auto Table, auto Index> = FieldPtr<Type, Table, Index, std::limits::u64_max()>;

struct ReinterpretVector<InitialType, WantedType> {
    u32 count;
    WantedType values[count / (sizeof(WantedType) / sizeof(InitialType))];
};

struct Vector<Type> {
    u32 count;
    Type values[count];
};

// > https://flatbuffers.dev/schema/#strings
// Strings are zero-terminated strings, prefixed by their length.
struct String {
    u32 length;
    // I prefer using length, but you may not, then remove length from []
    char content[length];
    // padding[4 - $ % 4];  // structure alignment, commented for disabling highlight
} [[format_read("format_string_read"), sealed]];

fn format_string_read(ref String string) {
    if (string.length == 0) {
        return "";
    }

    return std::format("{}", string.content);
};

// Note: fixed_size attribute doesn't pad the cursor, 
// so I have to manually move it using padding expression
// TODO: maybe export as section instead
struct NestedFlatbuffer<Type> {
    u32 size;
    Type value [[inline]];
    padding[size - sizeof(value)];
};
