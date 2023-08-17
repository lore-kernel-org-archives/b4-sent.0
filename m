From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Thu, 17 Aug 2023 11:21:52 -0500
Subject: [PATCH 1/2] powerpc/selftests: sort mm/.gitignore, add exec_prot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230817-powerpc-selftest-misc-v1-1-a84cc1ef78b2@linux.ibm.com>
References: <20230817-powerpc-selftest-misc-v1-0-a84cc1ef78b2@linux.ibm.com>
In-Reply-To: <20230817-powerpc-selftest-misc-v1-0-a84cc1ef78b2@linux.ibm.com>
To: Michael Ellerman <mpe@ellerman.id.au>, 
 Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>
Cc: linuxppc-dev@lists.ozlabs.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692289329; l=945;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=Z/88EbWN790XkVvb3x287idnDanC2WrxI0AE8kR6mLQ=;
 b=3juCn+J4s8cYIXbbbnSZR/ZRKw0HNMtREkvmbWpwXQrYuoc5DghUjRwkuYfbN1eB5Tl5l9Obq
 KSU/rS4ViOcAxJt8Cx839TwNdby8e+wN7JiGBkeaZIZsodmEjlJj2vo
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add exec_prot to to mm/.gitignore and sort the result.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
---
 tools/testing/selftests/powerpc/mm/.gitignore | 17 +++++++++--------
 1 file changed, 9 insertions(+), 8 deletions(-)

diff --git a/tools/testing/selftests/powerpc/mm/.gitignore b/tools/testing/selftests/powerpc/mm/.gitignore
index 4e1a294eec35..0df1a3afc5e2 100644
--- a/tools/testing/selftests/powerpc/mm/.gitignore
+++ b/tools/testing/selftests/powerpc/mm/.gitignore
@@ -1,15 +1,16 @@
 # SPDX-License-Identifier: GPL-2.0-only
+bad_accesses
+exec_prot
 hugetlb_vs_thp_test
-subpage_prot
-tempfile
-prot_sao
-segv_errors
-wild_bctr
 large_vm_fork_separation
-bad_accesses
-tlbie_test
+large_vm_gpr_corruption
 pkey_exec_prot
 pkey_siginfo
+prot_sao
+segv_errors
 stack_expansion_ldst
 stack_expansion_signal
-large_vm_gpr_corruption
+subpage_prot
+tempfile
+tlbie_test
+wild_bctr

-- 
2.41.0

