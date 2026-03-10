From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Mon, 09 Mar 2026 18:52:10 -0700
Subject: [PATCH v2 1/4] selftests: riscv: Add definition of BIT() macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260309-fix_selftests-v2-1-9d5a553a531e@gmail.com>
References: <20260309-fix_selftests-v2-0-9d5a553a531e@gmail.com>
In-Reply-To: <20260309-fix_selftests-v2-0-9d5a553a531e@gmail.com>
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773107537; l=2501;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=fSLPxH6GsBiaH5osUs3h11f7ItiKygcEvbUUMu8KVw8=;
 b=fBBjwRxbvodjq3RWghDxm+Dx/Qr/g8qqQkr3tyPeEL/UlTWkFSdguEjJ2AjRozlUJh2HkvnX7
 a0HUuIEIGH2BBtujgBtaN1UncVFwSqiGg8GtLvfObXDfUeBCaSvFPJL
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The BIT() macros is used by the validate_v_ptrace() test case, but not
defined. Include linux/bits.h to pull in this definition. To ensure that
the header in the kernel source is used, add tools/include to the header
search path.

Fixes: 30eb191c895b ("selftests: riscv: verify ptrace rejects invalid vector csr inputs")
Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 tools/testing/selftests/riscv/vector/Makefile            | 7 +++++--
 tools/testing/selftests/riscv/vector/validate_v_ptrace.c | 1 +
 2 files changed, 6 insertions(+), 2 deletions(-)

diff --git a/tools/testing/selftests/riscv/vector/Makefile b/tools/testing/selftests/riscv/vector/Makefile
index 326dafd739bf..f74a3aa63c87 100644
--- a/tools/testing/selftests/riscv/vector/Makefile
+++ b/tools/testing/selftests/riscv/vector/Makefile
@@ -2,6 +2,9 @@
 # Copyright (C) 2021 ARM Limited
 # Originally tools/testing/arm64/abi/Makefile
 
+NO_LIBC_CFLAGS := $(CFLAGS)
+CFLAGS += -I$(top_srcdir)/tools/include
+
 TEST_GEN_PROGS := v_initval vstate_prctl vstate_ptrace validate_v_ptrace
 TEST_GEN_PROGS_EXTENDED := vstate_exec_nolibc v_exec_initval_nolibc
 TEST_GEN_LIBS := v_helpers.c sys_hwprobe.c
@@ -21,14 +24,14 @@ $(OUTPUT)/vstate_prctl: vstate_prctl.c $(OUTPUT)/sys_hwprobe.o $(OUTPUT)/v_helpe
 
 $(OUTPUT)/vstate_exec_nolibc: vstate_exec_nolibc.c
 	$(CC) -nostdlib -static -include ../../../../include/nolibc/nolibc.h \
-		-Wall $(CFLAGS) $(LDFLAGS) $^ -o $@ -lgcc
+		-Wall $(NO_LIBC_CFLAGS) $(LDFLAGS) $^ -o $@ -lgcc
 
 $(OUTPUT)/v_initval: v_initval.c $(OUTPUT)/sys_hwprobe.o $(OUTPUT)/v_helpers.o
 	$(CC) -static -o$@ $(CFLAGS) $(LDFLAGS) $^
 
 $(OUTPUT)/v_exec_initval_nolibc: v_exec_initval_nolibc.c
 	$(CC) -nostdlib -static -include ../../../../include/nolibc/nolibc.h \
-		-Wall $(CFLAGS) $(LDFLAGS) $^ -o $@ -lgcc
+		-Wall $(NO_LIBC_CFLAGS) $(LDFLAGS) $^ -o $@ -lgcc
 
 $(OUTPUT)/vstate_ptrace: vstate_ptrace.c $(OUTPUT)/sys_hwprobe.o $(OUTPUT)/v_helpers.o
 	$(CC) -static -o$@ $(CFLAGS) $(LDFLAGS) $^
diff --git a/tools/testing/selftests/riscv/vector/validate_v_ptrace.c b/tools/testing/selftests/riscv/vector/validate_v_ptrace.c
index 3589549f7228..257de36274e9 100644
--- a/tools/testing/selftests/riscv/vector/validate_v_ptrace.c
+++ b/tools/testing/selftests/riscv/vector/validate_v_ptrace.c
@@ -6,6 +6,7 @@
 #include <unistd.h>
 #include <errno.h>
 
+#include <linux/bits.h>
 #include <linux/ptrace.h>
 #include <linux/elf.h>
 

-- 
2.52.0

