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
