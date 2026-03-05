From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Thu, 05 Mar 2026 00:11:31 -0800
Subject: [PATCH 3/4] riscv: ptrace: Fix BIT() compilation issues
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260305-fix_selftests-v1-3-61b62d23500b@gmail.com>
References: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
In-Reply-To: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772698321; l=1011;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=t37RqGcAuzbofdWiHpfRgZVkCDu2cWFOE4fQhY8Q/nQ=;
 b=pwecciV9DjRLq/2gHCdYoGcDPn1tWnba1BaX9qs7LAxqs0yHVratA1TL/I9YQ+2ZZd3/7VDVT
 PqwJHDwvVa9D+ZwzrENdIATzGGEn7e65aX7PX5Jot5MLvfHnRTIojpl
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BIT() is being used in ptrace.h without a definition, resulting in
compilation errors in tools/testing/selftests/riscv/cfi/cfitests.c:

cfitests.c:101:60: error: implicit declaration of function ‘BIT’ [-Wimplicit-function-declaration]
  101 |                      if ((cfi_reg.cfi_status.cfi_state & CFI_ENABLE_MASK) != CFI_ENABLE_MASK)

Include linux/bits.h to resolve this issue.

Fixes: 2af7c9cf021c ("riscv/ptrace: expose riscv CFI status and state via ptrace and in core files")
Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 arch/riscv/include/uapi/asm/ptrace.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/riscv/include/uapi/asm/ptrace.h b/arch/riscv/include/uapi/asm/ptrace.h
index 18988a5f1a63..5b53cea14355 100644
--- a/arch/riscv/include/uapi/asm/ptrace.h
+++ b/arch/riscv/include/uapi/asm/ptrace.h
@@ -8,6 +8,7 @@
 
 #ifndef __ASSEMBLER__
 
+#include <linux/bits.h>
 #include <linux/types.h>
 
 #define PTRACE_GETFDPIC		33

-- 
2.52.0

