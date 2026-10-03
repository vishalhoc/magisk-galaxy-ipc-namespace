#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <sched.h>
#include <unistd.h>
#include <stdarg.h>
#include <sys/syscall.h>

#ifndef CLONE_NEWIPC
#define CLONE_NEWIPC 0x08000000
#endif

#ifndef __NR_unshare
#define __NR_unshare 97
#endif

#ifndef __NR_clone
#define __NR_clone 220
#endif

// 1. Hook unshare()
int unshare(int flags) {
    static int (*real_unshare)(int) = NULL;
    if (!real_unshare) {
        real_unshare = (int (*)(int))dlsym(RTLD_NEXT, "unshare");
    }

    // Capability check: unshare(CLONE_NEWIPC) alone
    if (flags == CLONE_NEWIPC) {
        return 0; // Return success to capability probe
    }

    // Container launch: combined flags (e.g. CLONE_NEWNS | CLONE_NEWPID | CLONE_NEWIPC)
    if (flags & CLONE_NEWIPC) {
        flags &= ~CLONE_NEWIPC;
        if (flags == 0) return 0;
    }

    if (real_unshare) {
        return real_unshare(flags);
    }
    return (int)syscall(__NR_unshare, flags);
}

// 2. Hook clone()
int clone(int (*fn)(void *), void *stack, int flags, void *arg, ...) {
    static int (*real_clone)(int (*)(void *), void *, int, void *, ...) = NULL;
    if (!real_clone) {
        real_clone = (int (*)(int (*)(void *), void *, int, void *, ...))dlsym(RTLD_NEXT, "clone");
    }

    va_list args;
    va_start(args, arg);
    void *parent_tid = va_arg(args, void *);
    void *tls = va_arg(args, void *);
    void *child_tid = va_arg(args, void *);
    va_end(args);

    if (flags & CLONE_NEWIPC) {
        flags &= ~CLONE_NEWIPC;
    }

    if (real_clone) {
        return real_clone(fn, stack, flags, arg, parent_tid, tls, child_tid);
    }
    return -ENOSYS;
}

// 3. Hook direct syscall()
long syscall(long number, ...) {
    static long (*real_syscall)(long, ...) = NULL;
    if (!real_syscall) {
        real_syscall = (long (*)(long, ...))dlsym(RTLD_NEXT, "syscall");
    }

    va_list args;
    va_start(args, number);
    long a1 = va_arg(args, long);
    long a2 = va_arg(args, long);
    long a3 = va_arg(args, long);
    long a4 = va_arg(args, long);
    long a5 = va_arg(args, long);
    long a6 = va_arg(args, long);
    va_end(args);

    if (number == __NR_unshare) {
        if (a1 == CLONE_NEWIPC) {
            return 0;
        }
        if (a1 & CLONE_NEWIPC) {
            a1 &= ~CLONE_NEWIPC;
            if (a1 == 0) return 0;
        }
        if (real_syscall) {
            return real_syscall(__NR_unshare, a1);
        }
    }

    if (number == __NR_clone) {
        if (a1 & CLONE_NEWIPC) {
            a1 &= ~CLONE_NEWIPC;
        }
        if (real_syscall) {
            return real_syscall(__NR_clone, a1, a2, a3, a4, a5, a6);
        }
    }

    if (real_syscall) {
        return real_syscall(number, a1, a2, a3, a4, a5, a6);
    }
    return -ENOSYS;
}
