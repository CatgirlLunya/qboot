const std = @import("std");

pub const Frame = struct {
    eax: u32 = 0,
    ebx: u32 = 0,
    ecx: u32 = 0,
    edx: u32 = 0,
    edi: u32 = 0,
    esi: u32 = 0,
    ebp: u32 = 0,
    esp: u32 = 0,
    ss: u32 = 0,
    cs: u32 = 0,
    ds: u32 = 0,
    es: u32 = 0,
    fs: u32 = 0,
    gs: u32 = 0,
    eflags: u32 = 0,

    pub fn dump(self: *const Frame) void {
        std.log.info("EAX: {X}, EBX: {X}, ECX: {X}\nEDX: {X}, EDI: {X}, ESI: {X}\nEBP: {X}, ESP: {X}, SS:{X}\nCS: {X}, DS: {X}, ES: {X}\nFS: {X}, GS: {X}, EFLAGS: {X}", .{ self.eax, self.ebx, self.ecx, self.edx, self.edi, self.esi, self.ebp, self.esp, self.ss, self.cs, self.ds, self.es, self.fs, self.gs, self.eflags });
    }

    comptime {
        std.debug.assert(@sizeOf(@This()) == 60);
    }
};

pub inline fn getFrame() Frame {
    var frame: Frame = undefined;
    asm volatile (
        \\mov %eax, %[eax_loc]
        \\mov %ebx, %[ebx_loc]
        \\mov %ecx, %[ecx_loc]
        \\mov %edx, %[edx_loc]
        \\mov %edi, %[edi_loc]
        \\mov %esi, %[esi_loc]
        \\mov %ebp, %[ebp_loc]
        \\mov %esp, %[esp_loc]
        \\mov %ss, %[ss_loc]
        \\mov %cs, %[cs_loc]
        \\mov %ds, %[ds_loc]
        \\mov %es, %[es_loc]
        \\mov %fs, %[fs_loc]
        \\mov %gs, %[gs_loc]
        \\pushfd
        \\pop %[eflags_loc]
        :
        : [eax_loc] "p" (&frame.eax),
          [ebx_loc] "p" (&frame.ebx),
          [ecx_loc] "p" (&frame.ecx),
          [edx_loc] "p" (&frame.edx),
          [edi_loc] "p" (&frame.edi),
          [esi_loc] "p" (&frame.esi),
          [ebp_loc] "p" (&frame.ebp),
          [esp_loc] "p" (&frame.esp),
          [ss_loc] "p" (&frame.ss),
          [cs_loc] "p" (&frame.cs),
          [ds_loc] "p" (&frame.ds),
          [es_loc] "p" (&frame.es),
          [fs_loc] "p" (&frame.fs),
          [gs_loc] "p" (&frame.gs),
          [eflags_loc] "p" (&frame.eflags),
        : "memory"
    );
    return frame;
}
