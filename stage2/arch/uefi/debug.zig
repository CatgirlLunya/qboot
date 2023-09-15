pub fn breakpoint() void {
    while (true) asm volatile ("pause");
}
