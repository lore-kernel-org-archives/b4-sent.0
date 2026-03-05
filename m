From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Thu, 05 Mar 2026 00:11:29 -0800
Subject: [PATCH 1/4] selftests: riscv: Add definition of BIT() macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-fix_selftests-v1-1-61b62d23500b@gmail.com>
References: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
In-Reply-To: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772698321; l=1614;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=M9wZ+QYEsaJi68PSnz9JK4iYBoPubDLiHbEPbHDQLxE=;
 b=C/Lh7aPi35cf9hAmcFgh1b97ibEZIit+zZ7krQ7MxKyZjRNMGPA3EN4xr5iSQAuxYwSAp5avy
 DU94JT+vRpdA54bpDp7gvH+4ZHCs365DiBiOlsUYE0XkeewVPJE35eJ
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
 tools/testing/selftests/riscv/vector/Makefile            | 2 ++
 tools/testing/selftests/riscv/vector/validate_v_ptrace.c | 1 +
 2 files changed, 3 insertions(+)

diff --git a/tools/testing/selftests/riscv/vector/Makefile b/tools/testing/selftests/riscv/vector/Makefile
index 326dafd739bf..92c4cfe5f34d 100644
--- a/tools/testing/selftests/riscv/vector/Makefile
+++ b/tools/testing/selftests/riscv/vector/Makefile
@@ -2,6 +2,8 @@
 # Copyright (C) 2021 ARM Limited
 # Originally tools/testing/arm64/abi/Makefile
 
+CFLAGS += -I$(top_srcdir)/tools/include
+
 TEST_GEN_PROGS := v_initval vstate_prctl vstate_ptrace validate_v_ptrace
 TEST_GEN_PROGS_EXTENDED := vstate_exec_nolibc v_exec_initval_nolibc
 TEST_GEN_LIBS := v_helpers.c sys_hwprobe.c
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

