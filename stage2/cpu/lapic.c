#include "lapic.h"

bool LAPICInit(void) {
    return false;
}

union LAPICStatus LAPICGetStatus(void) {
    return (union LAPICStatus) {
        .value = rdmsr(APIC_STATUS_MSR),
    };
}

void LAPICSetStatus(union LAPICStatus status) {
    wrmsr(APIC_STATUS_MSR, status.value);
}

void LAPICEnable(struct SDT* madt) {
    union LAPICStatus status = LAPICGetStatus();
    status.enabled = true;
    LAPICSetStatus(status);
    APICWriteRegister(madt, 0xF0, 0xFF | APIC_SPURIOUS_INTERRUPT_ENABLE);
}

void APICWriteRegister(struct SDT* madt, uint16_t reg, uint32_t value) {
    *((uint32_t*)(madt->APIC.apic_address + reg)) = value;
}

uint32_t APICReadRegister(struct SDT* madt, uint16_t reg) {
    return *((uint32_t*)(madt->APIC.apic_address + reg));
}
