From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Sun, 09 Feb 2025 22:58:50 +0100
Subject: [PATCH] powerpc/fsl_lbc: Explicitly populate bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250209-localbus-v1-1-efcd780153a0@posteo.net>
X-B4-Tracking: v=1; b=H4sIABklqWcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDIwNL3Zz85MScpNJiXUuTRLPUpCQDk2RDIyWg8oKi1LTMCrBR0bG1tQD
 KGYEMWgAAAA==
X-Change-ID: 20250209-localbus-94a6ebb04c12
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Naveen N Rao <naveen@kernel.org>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1739138342; l=2166;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=B9wRS8xBkWgNM3MVMQKFspl9gtSoxY/bCMh2+zmQDxk=;
 b=tFftKrynp3tkKOIsn1G7hLG/50HmSiZgFICzklnzo02+5OzJ4z2O3yOXtbYkOd2tIUzTztvUP
 3jBRUyGXE5fDRuAWF65KNIo8wVffEwkkRvHkDHvXqMss2mBlUNCGA2P
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Historically, devicetree nodes representing the Freescale Enhanced
Local Bus Controller (eLBC) have compatible strings such as:

    compatible = "fsl,mpc8313-elbc", "fsl,elbc", "simple-bus";

The "simple-bus" string causes the bus to be populated, and the memory
devices contained within it to be discovered. The eLBC bus (as
represented in device trees) differs from a simple-bus in a few ways,
though:

 - Addresses are not simple/linear: The first cell of an address is a
   chip select, the second is an linear address within the space thus
   selected. Representing 1,0 as 100000000, for example, would decrease
   readability[1].
 - It is expected that the devices on a simple-bus "can be accessed
   directly without additional configuration required"[2], but the eLBC
   needs some configuration.

To accommodate devicetrees that declare an eLBC without "simple-bus",
explicitly populate the bus in the eLBC driver.

[1]: dtc makes such a suggestion opon encountering an eLBC
[2]: Quoting the Devicetree Specification Release v0.3

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/sysdev/fsl_lbc.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/arch/powerpc/sysdev/fsl_lbc.c b/arch/powerpc/sysdev/fsl_lbc.c
index 217cea150987df1e1b5c6dbf9e9a1607dd5ce49b..2007ced997fcf0c7059e5b780893b530764dc8b2 100644
--- a/arch/powerpc/sysdev/fsl_lbc.c
+++ b/arch/powerpc/sysdev/fsl_lbc.c
@@ -20,6 +20,7 @@
 #include <linux/of.h>
 #include <linux/of_address.h>
 #include <linux/of_irq.h>
+#include <linux/of_platform.h>
 #include <linux/slab.h>
 #include <linux/sched.h>
 #include <linux/platform_device.h>
@@ -336,7 +337,7 @@ static int fsl_lbc_ctrl_probe(struct platform_device *dev)
 	/* Enable interrupts for any detected events */
 	out_be32(&fsl_lbc_ctrl_dev->regs->lteir, LTEIR_ENABLE);
 
-	return 0;
+	return devm_of_platform_populate(&dev->dev);
 
 err1:
 	free_irq(fsl_lbc_ctrl_dev->irq[0], fsl_lbc_ctrl_dev);

---
base-commit: 7ccde445dddcca030cd6ed66974bb80915ad9dd5
change-id: 20250209-localbus-94a6ebb04c12

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

