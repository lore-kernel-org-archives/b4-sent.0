From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 12 Dec 2024 18:05:47 +0100
Subject: [PATCH 2/2] powerpc: Introduce and enforce assembler checks on GPR
 usage
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241212-gpr-checks-v1-2-8c084c5fc0b6@posteo.net>
References: <20241212-gpr-checks-v1-0-8c084c5fc0b6@posteo.net>
In-Reply-To: <20241212-gpr-checks-v1-0-8c084c5fc0b6@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734023157; l=3076;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=z8qAEvazTMW3Pn4yZzgH4+wLaoAxWPDN1wAhNikkFBM=;
 b=r2qxweIysC8VOQteqWQc+5BAwmiMWIszbrYzouFaC22bKQkd/X8tOpXoKH+SHx6QMGl8GXYYk
 388Bb9+knD7DB8dHJg4yvXhPgFOaP3NeZNiobhhCPTNyHYPY9OeEtAy
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PowerPC general-purpose registers are historically specified as plain
numbers (0-31), which makes them hard to distinguish from immediates.
For this reason, include/ppc_asm.tmpl defines aliases named r0-r31.
This can still lead to uncaught mistakes if a register is used in place
of a number.

Instead of (e.g.) 5 use %r5, which will result in an assembler warning
if used as a number. Turn these warnings into errors by passing
`--fatal-warnings` to the assembler.

I verified with gazerbeam_defconfig (MPC83xx) and qemu-ppce500_defconfig
(MPC85xx) that this patch results in the same machine code.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/config.mk |  2 +-
 include/ppc_asm.tmpl   | 66 +++++++++++++++++++++++++-------------------------
 2 files changed, 34 insertions(+), 34 deletions(-)

diff --git a/arch/powerpc/config.mk b/arch/powerpc/config.mk
index dd0124cace19be060d9374c440b0f35e5dbd801a..6e30df6504ecc62eff3dc3cb7d0a3e9cc9dcf4b3 100644
--- a/arch/powerpc/config.mk
+++ b/arch/powerpc/config.mk
@@ -8,7 +8,7 @@ LDFLAGS_FINAL += --bss-plt
 PLATFORM_RELFLAGS += -fpic -mrelocatable -ffunction-sections \
 -fdata-sections -mcall-linux
 
-PF_CPPFLAGS_POWERPC	:= $(call cc-option,-fno-ira-hoist-pressure,)
+PF_CPPFLAGS_POWERPC	:= $(call cc-option,-fno-ira-hoist-pressure,) $(call cc-option,-Xassembler --fatal-warnings,)
 PLATFORM_CPPFLAGS += -D__powerpc__ -ffixed-r2 -m32 $(PF_CPPFLAGS_POWERPC)
 KBUILD_LDFLAGS  += -m32 -melf32ppclinux
 
diff --git a/include/ppc_asm.tmpl b/include/ppc_asm.tmpl
index db7b1668d99a60ecd3992f0e090b37a7f0c23e00..0b858c41e32398d074069f9f0fdbc8e28d8e407e 100644
--- a/include/ppc_asm.tmpl
+++ b/include/ppc_asm.tmpl
@@ -45,40 +45,40 @@
 
 
 /***************************************************************************
- * Register names
+ * Register names. The %r1 offers some error-checking in GNU as.
  */
-#define	r0	0
-#define	r1	1
-#define	r2	2
-#define	r3	3
-#define	r4	4
-#define	r5	5
-#define	r6	6
-#define	r7	7
-#define	r8	8
-#define	r9	9
-#define	r10	10
-#define	r11	11
-#define	r12	12
-#define	r13	13
-#define	r14	14
-#define	r15	15
-#define	r16	16
-#define	r17	17
-#define	r18	18
-#define	r19	19
-#define	r20	20
-#define	r21	21
-#define	r22	22
-#define	r23	23
-#define	r24	24
-#define	r25	25
-#define	r26	26
-#define	r27	27
-#define	r28	28
-#define	r29	29
-#define	r30	30
-#define	r31	31
+#define	r0	%r0
+#define	r1	%r1
+#define	r2	%r2
+#define	r3	%r3
+#define	r4	%r4
+#define	r5	%r5
+#define	r6	%r6
+#define	r7	%r7
+#define	r8	%r8
+#define	r9	%r9
+#define	r10	%r10
+#define	r11	%r11
+#define	r12	%r12
+#define	r13	%r13
+#define	r14	%r14
+#define	r15	%r15
+#define	r16	%r16
+#define	r17	%r17
+#define	r18	%r18
+#define	r19	%r19
+#define	r20	%r20
+#define	r21	%r21
+#define	r22	%r22
+#define	r23	%r23
+#define	r24	%r24
+#define	r25	%r25
+#define	r26	%r26
+#define	r27	%r27
+#define	r28	%r28
+#define	r29	%r29
+#define	r30	%r30
+#define	r31	%r31
 
 #if defined(CONFIG_MPC8xx)
 

-- 
2.45.2

