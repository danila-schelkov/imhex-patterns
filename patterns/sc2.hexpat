#pragma description Supercell SWF flatbuffer file
#pragma endian little

import fbs;
import std.io;
import type.types.rust;

struct NestedFlatbuffer<Type> {
    u32 size;
    Type value [[inline]];
    padding[size - sizeof(value)];
};

struct Rect {
    f32 left, top, right, bottom;
};

struct MovieClipFrameElement {
    u16 child_index;
    u16 matrix_index;
    u16 color_transform_index;
} [[static]];

struct ShapePoint {
    f32 x, y;
    u16 u, v;
} [[static]];

struct Matrix2x3 {
    f32 a, b, c, d, x, y;
} [[static]];

struct ColorTransform {
    u8 ra, ga, ba, a, r, g, b;
} [[static]];

struct MatrixBank {
    RootTable table;

    Optional<Vector<Matrix2x3>, table, 0> matrices;
    Optional<Vector<ColorTransform>, table, 1> color_transforms;
    // Optional<Vector<String>, table, 2> short_matrices;
};

// Actually, "interners"
struct Resources {
    RootTable table;

    OptionalPtr<Vector<Ptr<String>>, table, 0> strings;
    OptionalPtr<Vector<u32>, table, 1> unk1;
    OptionalPtr<Vector<u32>, table, 2> unk2;
    OptionalPtr<Vector<Rect>, table, 3> scaling_grids;
    OptionalPtr<ReinterpretVector<u16, MovieClipFrameElement>, table, 4> movie_clip_elements;
    OptionalPtr<ReinterpretVector<u8, ShapePoint>, table, 5> shape_points;
    OptionalPtr<Vector<MatrixBank>, table, 6> matrix_banks;
};

struct Exports {
    RootTable table;

    Optional<Ptr<Vector<u16>>, table, 0> export_ids;
    Optional<Ptr<Vector<u32>>, table, 1> export_name_ids;
};

struct RGBA8 {
  u8 red   [[color("FF0000")]];
  u8 green [[color("00FF00")]];
  u8 blue  [[color("0000FF")]];
  u8 alpha [[color("FFFFFF")]];
} [[static, color(std::format("{:02X}{:02X}{:02X}", red, green, blue))]];

bitfield TextFieldStyles {
    useDeviceFont : 1;
    isOutlineEnabled : 1;
    isBold : 1;
    isItalic : 1;
    isMultiline : 1;
    unkBoolean : 1;
    autoAdjustFontSize : 1;
};

bitfield TextFieldAlignment {
    // 0 - start, 1 - end, 2 - justify
    horizontal : 3;  // 0 - left, 1 - right, 2 - justify
    vertical : 3;  // 0 - top, 1 - bottom, 2 - justify
};

struct TextField {
    u16 id;
    u16 unused0;
    i32 font_name_ref_id;
    i16 left, top, right, bottom;
    RGBA8 color;
    RGBA8 outline_color;
    i32 default_text_ref_id;
    i32 another_text_ref_id;
    TextFieldStyles styles;
    TextFieldAlignment align;
    u8 font_size;
    u8 unused1;
    i32 unused2;
};

struct TextFields {
    RootTable table;

    Optional<Ptr<Vector<TextField>>, table, 0> text_fields;
};

struct SupercellSWF {
    NestedFlatbuffer<Resources> resources;
    NestedFlatbuffer<Exports> exports;
    NestedFlatbuffer<TextFields> text_fields;
    // NestedFlatbuffer<Shapes> shapes;
    // NestedFlatbuffer<MovieClips> movie_clips;
    // NestedFlatbuffer<MovieClipModifiers> movie_clip_modifiers;
    // NestedFlatbuffer<TextureSets> texture_sets;
};

SupercellSWF swf @ 0x00;
