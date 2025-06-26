#pragma description Supercell SWF flatbuffer file
#pragma endian little

import fbs;
import std.io;

using f32 = float;

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

struct SupercellSWF {
    NestedFlatbuffer<Resources> resources;
};

SupercellSWF swf @ 0x00;