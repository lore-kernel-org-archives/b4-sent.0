From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Thu, 05 Mar 2026 00:11:32 -0800
Subject: [PATCH 4/4] selftests: riscv: Add license to cfi selftest
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260305-fix_selftests-v1-4-61b62d23500b@gmail.com>
References: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
In-Reply-To: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772698321; l=597;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=BASghyhUbPQR3TaCTFC1Bxb1DJuKTtAvjw5yHhn6X94=;
 b=lJ0mzQxUxYW7xpr4ssXjgSI8+lMx7NSdTsAffUyoUAlkm3NsAqEX0NnmwgQl90DM5nKUkE2Ol
 iwQ51FDEMj1BmgGXixIaUwyqZuUjPg4nvPFvJoh8E5HgBpvT4rK4KgZ
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The cfi selftest was missing a license so add it.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 tools/testing/selftests/riscv/cfi/Makefile | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/tools/testing/selftests/riscv/cfi/Makefile b/tools/testing/selftests/riscv/cfi/Makefile
index 96a4dc4b69c3..93b4738c0e2e 100644
--- a/tools/testing/selftests/riscv/cfi/Makefile
+++ b/tools/testing/selftests/riscv/cfi/Makefile
@@ -1,3 +1,5 @@
+# SPDX-License-Identifier: GPL-2.0
+
 CFLAGS += $(KHDR_INCLUDES)
 CFLAGS += -I$(top_srcdir)/tools/include
 

-- 
2.52.0

