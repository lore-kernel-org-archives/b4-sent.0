From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Mon, 09 Mar 2026 18:52:11 -0700
Subject: [PATCH v2 2/4] selftests: riscv: Add braces around EXPECT_EQ()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260309-fix_selftests-v2-2-9d5a553a531e@gmail.com>
References: <20260309-fix_selftests-v2-0-9d5a553a531e@gmail.com>
In-Reply-To: <20260309-fix_selftests-v2-0-9d5a553a531e@gmail.com>
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773107537; l=2373;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=7v3hKOxSt+L+8LtCfZh085q396U9Poj6cOIz6NZfRCU=;
 b=S2N9TZ8zWVgCVD+QvRzprkQEUmAHkc0wdE0k32fG4zPv1gMn1F6ZCLgFxIaK3ZXubqJTZ9voc
 cIxu3B7Sm6hBEdbeQLlyIRpfWbeEc6tgeXvqabXhadGrbzqNGjA6diN
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=vpF2USrG+aB6CTbSt34rzJKsAVe/l+GAXo1IomCMETk=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/2026030 with auth_id=663
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

EXPECT_EQ() expands to multiple lines, breaking up one-line if
statements. This issue was not present in the patch on the mailing list
but was instead introduced by the maintainer when attempting to fix up
checkpatch warnings. Add braces around EXPECT_EQ() to avoid the error
even though checkpatch suggests them to be removed:

validate_v_ptrace.c:626:17: error: ‘else’ without a previous ‘if’

Fixes: 3789d5eecd5a ("selftests: riscv: verify syscalls discard vector context")
Fixes: 30eb191c895b ("selftests: riscv: verify ptrace rejects invalid vector csr inputs")
Fixes: 849f05ae1ea6 ("selftests: riscv: verify ptrace accepts valid vector csr values")
Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 tools/testing/selftests/riscv/vector/validate_v_ptrace.c | 15 +++++++++------
 1 file changed, 9 insertions(+), 6 deletions(-)

diff --git a/tools/testing/selftests/riscv/vector/validate_v_ptrace.c b/tools/testing/selftests/riscv/vector/validate_v_ptrace.c
index 257de36274e9..5724e6eb3309 100644
--- a/tools/testing/selftests/riscv/vector/validate_v_ptrace.c
+++ b/tools/testing/selftests/riscv/vector/validate_v_ptrace.c
@@ -291,10 +291,11 @@ TEST(ptrace_v_syscall_clobbering)
 
 		/* verify initial vsetvli settings */
 
-		if (is_xtheadvector_supported())
+		if (is_xtheadvector_supported()) {
 			EXPECT_EQ(5UL, regset_data->vtype);
-		else
+		} else {
 			EXPECT_EQ(9UL, regset_data->vtype);
+		}
 
 		EXPECT_EQ(regset_data->vlenb, regset_data->vl);
 		EXPECT_EQ(vlenb, regset_data->vlenb);
@@ -620,10 +621,11 @@ TEST_F(v_csr_invalid, ptrace_v_invalid_values)
 
 		/* verify initial vsetvli settings */
 
-		if (is_xtheadvector_supported())
+		if (is_xtheadvector_supported()) {
 			EXPECT_EQ(5UL, regset_data->vtype);
-		else
+		} else {
 			EXPECT_EQ(9UL, regset_data->vtype);
+		}
 
 		EXPECT_EQ(regset_data->vlenb, regset_data->vl);
 		EXPECT_EQ(vlenb, regset_data->vlenb);
@@ -828,10 +830,11 @@ TEST_F(v_csr_valid, ptrace_v_valid_values)
 
 		/* verify initial vsetvli settings */
 
-		if (is_xtheadvector_supported())
+		if (is_xtheadvector_supported()) {
 			EXPECT_EQ(5UL, regset_data->vtype);
-		else
+		} else {
 			EXPECT_EQ(9UL, regset_data->vtype);
+		}
 
 		EXPECT_EQ(regset_data->vlenb, regset_data->vl);
 		EXPECT_EQ(vlenb, regset_data->vlenb);

-- 
2.52.0

