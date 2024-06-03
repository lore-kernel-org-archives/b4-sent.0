From: Nathan Lynch <nathanl@linux.ibm.com>
Date: Mon, 03 Jun 2024 08:01:03 -0500
Subject: [PATCH] powerpc/crypto: Add generated P8 asm to .gitignore
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-powerpc-crypto-ignore-p8-asm-v1-1-05843fec2bb7@linux.ibm.com>
X-B4-Tracking: v=1; b=H4sIAI6+XWYC/x3MOw6DMAwA0Ksgz1hy+VSlV0EdosSAhyaWU1EQ4
 u5EjG95B2Q24Qzv6gDjVbKkWPCoK/CLizOjhGJoqOnoSS1q+rOpR2+7/hLKHJMx6gtd/mIXhqk
 fgiNqGUqhxpNsdz9+zvMCr/+Njm4AAAA=
To: Herbert Xu <herbert@gondor.apana.org.au>, 
 "David S. Miller" <davem@davemloft.net>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>, 
 Danny Tsen <dtsen@linux.ibm.com>
Cc: linux-crypto@vger.kernel.org, linuxppc-dev@lists.ozlabs.org, 
 linux-kernel@vger.kernel.org, Nathan Lynch <nathanl@linux.ibm.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717419668; l=931;
 i=nathanl@linux.ibm.com; s=20230817; h=from:subject:message-id;
 bh=QihzfT/yvBcFqpbTNR7ndCqh7WaXVJqXBsXhRlZPQ90=;
 b=QGuEuclbxZu65XOLMH9NK3EWtZhcZw+0yN7nFsIHy+I7MoKKPXUPvM7Gsd3TDDsqn7GmZ3CUN
 CjIqTKmsh3OARa/D/u5bqr2EQMRnMMb17I33uslOf1hxKx6/We9aCDd
X-Developer-Key: i=nathanl@linux.ibm.com; a=ed25519;
 pk=jPDF44RvT+9DGFOH3NGoIu1xN9dF+82pjdpnKjXfoJ0=
X-Endpoint-Received: by B4 Relay for nathanl@linux.ibm.com/20230817 with auth_id=78
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Looks like drivers/crypto/vmx/.gitignore should have been merged into
arch/powerpc/crypto/.gitignore as part of commit
109303336a0c ("crypto: vmx - Move to arch/powerpc/crypto") so that all
generated asm files are ignored.

Signed-off-by: Nathan Lynch <nathanl@linux.ibm.com>
Fixes: 109303336a0c ("crypto: vmx - Move to arch/powerpc/crypto")
---
 arch/powerpc/crypto/.gitignore | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/powerpc/crypto/.gitignore b/arch/powerpc/crypto/.gitignore
index e1094f08f713..e9fe73aac8b6 100644
--- a/arch/powerpc/crypto/.gitignore
+++ b/arch/powerpc/crypto/.gitignore
@@ -1,3 +1,5 @@
 # SPDX-License-Identifier: GPL-2.0-only
 aesp10-ppc.S
+aesp8-ppc.S
 ghashp10-ppc.S
+ghashp8-ppc.S

---
base-commit: be2fc65d66e0406cc9d39d40becaecdf4ee765f3
change-id: 20240603-powerpc-crypto-ignore-p8-asm-4d9f59da003e

Best regards,
-- 
Nathan Lynch <nathanl@linux.ibm.com>

