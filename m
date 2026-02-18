From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Tue, 17 Feb 2026 18:26:52 -0800
Subject: [PATCH] lib: sbi: Use SBI_SSE_EVENT_LOCAL_UNKNOWN_NMI with unknown
 interrupts
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260217-nmi-v1-1-eb4b4b3ad70e@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDI0Nz3bzcTF1DQwMzk8Q0i1QLS3MloMqCotS0zAqwKdGxtbUAeaIgOVU
 AAAA=
X-Change-ID: 20260217-nmi-11064af8e897
To: opensbi@lists.infradead.org
Cc: weidongwd <weidong.wd@bytedance.com>, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771381642; l=1611;
 i=thecharlesjenkins@gmail.com; s=20260127; h=from:subject:message-id;
 bh=wBmA1uCady5afkTbF2Zn1Dnq+RrIayl1Lm/3nWl038Q=;
 b=9oWZXe+Yfn/amm2DXhp3kF3HOgZBAe8Hwc9oMLqyD5njXM9Eq5ov4+IN+1Scx1frH10YGo2BZ
 e7criYzhQCFBtItTpuvSUNzrGqTGfjGKVnA3gZ9huYGl43z/foJ7bwr
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=4AzEw2rmBYSzmHkYTjITwPc2sWIvqjw/Fu3GnQmSMTI=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260127 with auth_id=619
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An mcause of 0 means "unknown cause" according to the riscv priviledged
spec. When this occurs, the interrupt should be forwarded to S-mode
software via SBI_SSE_EVENT_GLOBAL_UNKNOWN_NMI if SSE is enabled.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
This patch builds off of [1] to trigger the UNKNOWN_NMI SSE call. That
patch depends on the SBI spec patch [2].

[1] https://lore.kernel.org/opensbi/20251014055330.59506-1-weidong.wd@bytedance.com/
[2] https://github.com/riscv-non-isa/riscv-sbi-doc/pull/223
---
 include/sbi/riscv_encoding.h | 1 +
 lib/sbi/sbi_trap.c           | 4 ++++
 2 files changed, 5 insertions(+)

diff --git a/include/sbi/riscv_encoding.h b/include/sbi/riscv_encoding.h
index b5a4ce81..1c634a45 100644
--- a/include/sbi/riscv_encoding.h
+++ b/include/sbi/riscv_encoding.h
@@ -90,6 +90,7 @@
 
 #define MCAUSE_IRQ_MASK			(_UL(1) << (__riscv_xlen - 1))
 
+#define IRQ_UNKNOWN			0
 #define IRQ_S_SOFT			1
 #define IRQ_VS_SOFT			2
 #define IRQ_M_SOFT			3
diff --git a/lib/sbi/sbi_trap.c b/lib/sbi/sbi_trap.c
index f41db4d1..f6576bd9 100644
--- a/lib/sbi/sbi_trap.c
+++ b/lib/sbi/sbi_trap.c
@@ -234,6 +234,10 @@ int sbi_trap_redirect(struct sbi_trap_regs *regs,
 static int sbi_trap_nonaia_irq(unsigned long irq)
 {
 	switch (irq) {
+#if defined(CONFIG_SBI_ECALL_SSE)
+	case IRQ_UNKNOWN:
+		return sbi_sse_inject_event(SBI_SSE_EVENT_LOCAL_UNKNOWN_NMI);
+#endif
 	case IRQ_M_TIMER:
 		sbi_timer_process();
 		break;

---
base-commit: b27ecec76b8acfece9c28078d02cbc6bc762135c
change-id: 20260217-nmi-11064af8e897

- Charlie

