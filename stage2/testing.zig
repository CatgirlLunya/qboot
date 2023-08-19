pub fn div_by_zero() noreturn {
    const value = 0;
    asm volatile ("idiv %[value]"
        :
        : [value] "r" (value),
    );
    @panic("Divide by zero returned!");
}
