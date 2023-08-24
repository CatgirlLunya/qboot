pub fn div_by_zero() noreturn {
    asm volatile ("idiv %[value]"
        :
        : [value] "r" (0),
    );
    @panic("Divide by zero returned!");
}
