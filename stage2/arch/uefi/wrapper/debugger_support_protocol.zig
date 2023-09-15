const uefi = @import("std").os.uefi;
const protocol = @import("protocol.zig");
const std = @import("std");

pub const DebuggerSupportProtocol = extern struct {
    pub const PeriodicCallback = *const fn (context: SystemContext) callconv(uefi.cc) void;
    pub const ExceptionCallback = *const fn (exception_type: isize, context: SystemContext) callconv(uefi.cc) void;
    pub const InstructionSetArchitecture = enum(u32) {
        IsaIA32 = 0x014C,
        IsaX64 = 0x8664,
        IsaIpf = 0x0200,
        IsaEbc = 0x0EBC,
        IsaArm = 0x01C2,
        IsaAArch64 = 0xAA64,
    };

    isa: InstructionSetArchitecture,
    _getMaximumProcessorIndex: *const fn (*const DebuggerSupportProtocol, max_processor_index: *usize) callconv(uefi.cc) uefi.Status,
    _registerPeriodicCallback: *const fn (*const DebuggerSupportProtocol, processor_index: usize, callback: ?PeriodicCallback) callconv(uefi.cc) uefi.Status,
    _registerExceptionCallback: *const fn (*const DebuggerSupportProtocol, processor_index: usize, callback: ?ExceptionCallback, exception_type: u32) callconv(uefi.cc) uefi.Status,
    _invalidateInstructionCache: *const fn (*const DebuggerSupportProtocol, processor_index: usize, base: *const u8, size: usize) callconv(uefi.cc) uefi.Status,

    pub fn getMaximumProcessorIndex(self: *const DebuggerSupportProtocol, max_processor_index: *usize) uefi.Status {
        return self._getMaximumProcessorIndex(self, max_processor_index);
    }

    pub fn registerPeriodicCallback(self: *const DebuggerSupportProtocol, processor_index: usize, callback: ?PeriodicCallback) uefi.Status {
        return self._registerPeriodicCallback(self, processor_index, callback);
    }

    pub fn registerExceptionCallback(self: *const DebuggerSupportProtocol, processor_index: usize, callback: ?ExceptionCallback, exception_type: u32) uefi.Status {
        return self._registerExceptionCallback(self, processor_index, callback, exception_type);
    }

    pub fn invalidateInstructionCache(self: *const DebuggerSupportProtocol, processor_index: usize, base: *const u8, size: usize) uefi.Status {
        return self._invalidateInstructionCache(self, processor_index, base, size);
    }

    pub const guid align(8) = uefi.Guid{
        .time_low = 0x2755590c,
        .time_mid = 0x6f3c,
        .time_high_and_version = 0x42fa,
        .clock_seq_high_and_reserved = 0x9e,
        .clock_seq_low = 0xa4,
        .node = [_]u8{ 0xa3, 0xba, 0x54, 0x3c, 0xda, 0x25 },
    };
};

pub fn open() ![]protocol.protocolHandlePair(DebuggerSupportProtocol) {
    return protocol.openProtocols(DebuggerSupportProtocol);
}

pub fn close(protocols: []protocol.protocolHandlePair(DebuggerSupportProtocol)) !void {
    return protocol.closeProtocols(DebuggerSupportProtocol, protocols);
}

const SystemContextEbc = extern struct {
    r0: u64,
    r1: u64,
    r2: u64,
    r3: u64,
    r4: u64,
    r5: u64,
    r6: u64,
    r7: u64,
    flags: u64,
    control_flags: u64,
    ip: u64,
};

const FxSaveStateIA32 = extern struct {
    fcw: u16,
    fsw: u16,
    ftw: u16,
    opcode: u16,
    eip: u32,
    cs: u16,
    res0: u16,
    data_offset: u32,
    ds: u16,
    res1: [10]u8,
    st0mm0: [10]u8,
    res2: [6]u8,
    st1mm1: [10]u8,
    res3: [6]u8,
    st2mm2: [10]u8,
    res4: [6]u8,
    st3mm3: [10]u8,
    res5: [6]u8,
    st4mm4: [10]u8,
    res6: [6]u8,
    st5mm5: [10]u8,
    res7: [6]u8,
    st6mm6: [10]u8,
    res8: [6]u8,
    st7mm7: [10]u8,
    res9: [6]u8,
    xmm0: [16]u8,
    xmm1: [16]u8,
    xmm2: [16]u8,
    xmm3: [16]u8,
    xmm4: [16]u8,
    xmm5: [16]u8,
    xmm6: [16]u8,
    xmm7: [16]u8,
    res10: [14 * 16]u8,
};

const SystemContextIa32 = extern struct {
    exception_data: u32,
    fx_save_state: FxSaveStateIA32,
    dr0: u32,
    dr1: u32,
    dr2: u32,
    dr3: u32,
    dr6: u32,
    dr7: u32,
    cr0: u32,
    cr1: u32,
    cr2: u32,
    cr3: u32,
    cr4: u32,
    eflags: u32,
    ldtr: u32,
    tr: u32,
    gdtr: [2]u32,
    idtr: [2]u32,
    eip: u32,
    gs: u32,
    fs: u32,
    es: u32,
    ds: u32,
    cs: u32,
    ss: u32,
    edi: u32,
    esi: u32,
    ebp: u32,
    esp: u32,
    ebx: u32,
    edx: u32,
    ecx: u32,
    eax: u32,
};

const FxSaveStateX64 = extern struct {
    fcw: u16,
    fsw: u16,
    ftw: u16,
    opcode: u16,
    rip: u64,
    data_offset: u64,
    res1: [10]u8,
    st0mm0: [10]u8,
    res2: [6]u8,
    st1mm1: [10]u8,
    res3: [6]u8,
    st2mm2: [10]u8,
    res4: [6]u8,
    st3mm3: [10]u8,
    res5: [6]u8,
    st4mm4: [10]u8,
    res6: [6]u8,
    st5mm5: [10]u8,
    res7: [6]u8,
    st6mm6: [10]u8,
    res8: [6]u8,
    st7mm7: [10]u8,
    res9: [6]u8,
    xmm0: [16]u8,
    xmm1: [16]u8,
    xmm2: [16]u8,
    xmm3: [16]u8,
    xmm4: [16]u8,
    xmm5: [16]u8,
    xmm6: [16]u8,
    xmm7: [16]u8,
    res10: [14 * 16]u8,
};

const SystemContextX64 = extern struct {
    exception_data: u64,
    fx_save_state: FxSaveStateX64,
    dr0: u64,
    dr1: u64,
    dr2: u64,
    dr3: u64,
    dr6: u64,
    dr7: u64,
    cr0: u64,
    cr1: u64,
    cr2: u64,
    cr3: u64,
    cr4: u64,
    cr8: u64,
    rflags: u64,
    ldtr: u64,
    tr: u64,
    gdtr: [2]u64,
    idtr: [2]u64,
    rip: u64,
    gs: u64,
    fs: u64,
    es: u64,
    ds: u64,
    cs: u64,
    ss: u64,
    rdi: u64,
    rsi: u64,
    rbp: u64,
    rsp: u64,
    rbx: u64,
    rdx: u64,
    rcx: u64,
    rax: u64,
    r8: u64,
    r9: u64,
    r10: u64,
    r11: u64,
    r12: u64,
    r13: u64,
    r14: u64,
    r15: u64,
};

const SystemContextIpf = extern struct {
    res: u64,
    r: [32]u64,
    f: [32][2]u64,
    pr: u64,
    b: [8]u64,
    ar_rsc: u64,
    ar_bsp: u64,
    ar_bsp_store: u64,
    ar_rnat: u64,
    ar_fcr: u64,
    ar_eflag: u64,
    ar_csd: u64,
    ar_ssd: u64,
    ar_cflg: u64,
    ar_fsr: u64,
    ar_fir: u64,
    ar_fdr: u64,
    ar_ccv: u64,
    ar_unat: u64,
    ar_fpsr: u64,
    ar_pfs: u64,
    ar_lc: u64,
    ar_ec: u64,
    cr_dcr: u64,
    cr_itm: u64,
    cr_iva: u64,
    cr_ptr: u64,
    cr_ipsr: u64,
    cr_isr: u64,
    cr_iip: u64,
    cr_ifa: u64,
    cr_itir: u64,
    cr_iipa: u64,
    cr_ifs: u64,
    cr_iim: u64,
    cr_iha: u64,
    dbr: [8]u64,
    ibr: [8]u64,
    int_nat: u64,
};

const SystemContextArm = extern struct {
    r: [13]u32,
    sp: u32,
    lr: u32,
    pc: u32,
    cpsr: u32,
    dfsr: u32,
    dfar: u32,
    ifsr: u32,
    ifar: u32,
};

const SystemContextAarch64 = extern struct {
    x: [29]u64,
    fp: u64,
    lr: u64,
    sp: u64,
    v: [32][2]u64,
    elr: u64,
    spsr: u64,
    fpsr: u64,
    esr: u64,
    far: u64,
};

pub const SystemContext = extern union {
    ebc: *SystemContextEbc,
    ia32: *SystemContextIa32,
    x64: *SystemContextX64,
    ipf: *SystemContextIpf,
    arm: *SystemContextArm,
    aarch64: *SystemContextAarch64,
};
