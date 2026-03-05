From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Thu, 05 Mar 2026 00:11:30 -0800
Subject: [PATCH 2/4] selftests: riscv: Add braces around EXPECT_EQ()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260305-fix_selftests-v1-2-61b62d23500b@gmail.com>
References: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
In-Reply-To: <20260305-fix_selftests-v1-0-61b62d23500b@gmail.com>
To: Shuah Khan <shuah@kernel.org>, Paul Walmsley <pjw@kernel.org>, 
 Palmer Dabbelt <palmer@dabbelt.com>, 
 Sergey Matyukevich <geomatsi@gmail.com>, Andy Chiu <andybnac@gmail.com>, 
 Deepak Gupta <debug@rivosinc.com>
Cc: linux-kselftest@vger.kernel.org, linux-riscv@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1772698321; l=2373;
 i=thecharlesjenkins@gmail.com; s=2026030; h=from:subject:message-id;
 bh=7v3hKOxSt+L+8LtCfZh085q396U9Poj6cOIz6NZfRCU=;
 b=Sq295+AKQQFINYQEs3JVoWOvokFXidLJ16vqhMSgXrs+qeDEBg2Bsqzq3t3yeHAYLKFS8YzVI
 lMB1g2/JAyhBYHhOGkxarQsvqBREbStMSMkmw1hZ9HeKbCRxs/ZzXQ0
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

