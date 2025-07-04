
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

fn get_field_address(ref RootTable table, u32 field_index) {
    if (table.vtable.field_count <= field_index) {
        return std::limits::u64_max();
    }

    u16 field_offset = table.vtable.field_offsets[field_index];
    if (field_offset == 0) {
        return std::limits::u64_max();
    }

    return addressof(table.vtable_offset) + field_offset;
};

struct Optional<Type, auto Table, auto Index> {
    u64 field_address = get_field_address(Table, Index);
    if (field_address != std::limits::u64_max()) {
        Type value @ field_address;
    }
} [[format_read("format_optional_read")]];

fn format_optional_read(ref auto optional) {
    if (optional.field_address == std::limits::u64_max()) {
        return "undefined";
    }

    return std::format("{}", optional.value);
};

struct Ptr<Type> {
    u32 offset;
    Type value @ addressof(offset) + offset;
} [[format_read("format_ptr_read")]];

fn format_ptr_read(ref Ptr<auto> ptr) {
    return ptr.value;
};

struct OptionalPtr<Type, auto Table, auto Index> {
    u64 field_address = get_field_address(Table, Index);
    if (field_address != std::limits::u64_max()) {
        Ptr<Type> value @ field_address [[inline]];
    }
};

struct ReinterpretVector<InitialType, WantedType> {
    u32 count;
    WantedType values[count / (sizeof(WantedType) / sizeof(InitialType))];
};

struct Vector<Type> {
    u32 count;
    Type values[count];
};

struct String {
    u32 length;
    char content[length];
} [[format_read("format_string_read"), sealed]];

fn format_string_read(ref String string) {
    if (string.length == 0) {
        return "";
    }

    return std::format("{}", string.content);
};
