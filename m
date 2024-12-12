From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Date: Thu, 12 Dec 2024 18:05:46 +0100
Subject: [PATCH 1/2] powerpc: Fix 0 vs. r0 confusion in X/D-form
 instructions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241212-gpr-checks-v1-1-8c084c5fc0b6@posteo.net>
References: <20241212-gpr-checks-v1-0-8c084c5fc0b6@posteo.net>
In-Reply-To: <20241212-gpr-checks-v1-0-8c084c5fc0b6@posteo.net>
To: Mario Six <mario.six@gdsys.cc>, Tom Rini <trini@konsulko.com>, 
 =?utf-8?q?Marek_Beh=C3=BAn?= <kabel@kernel.org>
Cc: u-boot@lists.denx.de, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1734023157; l=9111;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=2bgiDR4Lz5uVTbcNn/SGCs9Hwul5Fw2IInILLe//TEY=;
 b=qpqfXhIf7NMaNkDLYtgcgksBOPyMUMwT1OMkfr07MYqmDP6tArj5rLO8Q0QY07t1W1KKWT7se
 9fLt6gz+f60DA2zmNqWmxq+dIqp3sFacTyNdAxciAKXgSOeMSdFFSk/
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instructions such as dcbi are in the X-form; they have RA and RB fields
and the effective address (EA) is computed as (RA|0)+(RB). In words,
this means that if RA is zero, the left-hand side of the addition is
zero, otherwise the corresponding GPR is used. r0 can never be used on
the left-hand side of a X-form instruction.

For D-form instructions such as addis, the Power ISA illustrates this in
the instruction pseudo-code:

	if RA = 0 then RT <-        EXTS(SI || 0x0000)
	else           RT <- (RA) + EXIS(SI || 0x0000)

In all of these cases, RA=0 indicates the value zero, not register r0.

I verified with gazerbeam_defconfig (MPC83xx) and qemu-ppce500_defconfig
(MPC85xx) that this patch results in the same machine code.

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
 arch/powerpc/cpu/mpc83xx/start.S | 72 ++++++++++++++++++++--------------------
 arch/powerpc/cpu/mpc85xx/start.S | 24 +++++++-------
 arch/powerpc/lib/ppccache.S      |  6 ++--
 3 files changed, 51 insertions(+), 51 deletions(-)

diff --git a/arch/powerpc/cpu/mpc83xx/start.S b/arch/powerpc/cpu/mpc83xx/start.S
index 78762f000dfd35568838654e11c2bc38a5b40e90..0d8bc4641176b9c5e45158b8455e1989de0c3b91 100644
--- a/arch/powerpc/cpu/mpc83xx/start.S
+++ b/arch/powerpc/cpu/mpc83xx/start.S
@@ -550,133 +550,133 @@ init_e300_core: /* time t 10 */
 	/* setup_bats - set them up to some initial state */
 	.globl	setup_bats
 setup_bats:
-	addis	r0, r0, 0x0000
+	addis	r0, 0, 0x0000
 
 	/* IBAT 0 */
-	addis	r4, r0, CFG_SYS_IBAT0L@h
+	addis	r4,  0, CFG_SYS_IBAT0L@h
 	ori	r4, r4, CFG_SYS_IBAT0L@l
-	addis	r3, r0, CFG_SYS_IBAT0U@h
+	addis	r3,  0, CFG_SYS_IBAT0U@h
 	ori	r3, r3, CFG_SYS_IBAT0U@l
 	mtspr	IBAT0L, r4
 	mtspr	IBAT0U, r3
 
 	/* DBAT 0 */
-	addis	r4, r0, CFG_SYS_DBAT0L@h
+	addis	r4,  0, CFG_SYS_DBAT0L@h
 	ori	r4, r4, CFG_SYS_DBAT0L@l
-	addis	r3, r0, CFG_SYS_DBAT0U@h
+	addis	r3,  0, CFG_SYS_DBAT0U@h
 	ori	r3, r3, CFG_SYS_DBAT0U@l
 	mtspr	DBAT0L, r4
 	mtspr	DBAT0U, r3
 
 	/* IBAT 1 */
-	addis	r4, r0, CFG_SYS_IBAT1L@h
+	addis	r4,  0, CFG_SYS_IBAT1L@h
 	ori	r4, r4, CFG_SYS_IBAT1L@l
-	addis	r3, r0, CFG_SYS_IBAT1U@h
+	addis	r3,  0, CFG_SYS_IBAT1U@h
 	ori	r3, r3, CFG_SYS_IBAT1U@l
 	mtspr	IBAT1L, r4
 	mtspr	IBAT1U, r3
 
 	/* DBAT 1 */
-	addis	r4, r0, CFG_SYS_DBAT1L@h
+	addis	r4,  0, CFG_SYS_DBAT1L@h
 	ori	r4, r4, CFG_SYS_DBAT1L@l
-	addis	r3, r0, CFG_SYS_DBAT1U@h
+	addis	r3,  0, CFG_SYS_DBAT1U@h
 	ori	r3, r3, CFG_SYS_DBAT1U@l
 	mtspr	DBAT1L, r4
 	mtspr	DBAT1U, r3
 
 	/* IBAT 2 */
-	addis	r4, r0, CFG_SYS_IBAT2L@h
+	addis	r4,  0, CFG_SYS_IBAT2L@h
 	ori	r4, r4, CFG_SYS_IBAT2L@l
-	addis	r3, r0, CFG_SYS_IBAT2U@h
+	addis	r3,  0, CFG_SYS_IBAT2U@h
 	ori	r3, r3, CFG_SYS_IBAT2U@l
 	mtspr	IBAT2L, r4
 	mtspr	IBAT2U, r3
 
 	/* DBAT 2 */
-	addis	r4, r0, CFG_SYS_DBAT2L@h
+	addis	r4,  0, CFG_SYS_DBAT2L@h
 	ori	r4, r4, CFG_SYS_DBAT2L@l
-	addis	r3, r0, CFG_SYS_DBAT2U@h
+	addis	r3,  0, CFG_SYS_DBAT2U@h
 	ori	r3, r3, CFG_SYS_DBAT2U@l
 	mtspr	DBAT2L, r4
 	mtspr	DBAT2U, r3
 
 	/* IBAT 3 */
-	addis	r4, r0, CFG_SYS_IBAT3L@h
+	addis	r4,  0, CFG_SYS_IBAT3L@h
 	ori	r4, r4, CFG_SYS_IBAT3L@l
-	addis	r3, r0, CFG_SYS_IBAT3U@h
+	addis	r3,  0, CFG_SYS_IBAT3U@h
 	ori	r3, r3, CFG_SYS_IBAT3U@l
 	mtspr	IBAT3L, r4
 	mtspr	IBAT3U, r3
 
 	/* DBAT 3 */
-	addis	r4, r0, CFG_SYS_DBAT3L@h
+	addis	r4,  0, CFG_SYS_DBAT3L@h
 	ori	r4, r4, CFG_SYS_DBAT3L@l
-	addis	r3, r0, CFG_SYS_DBAT3U@h
+	addis	r3,  0, CFG_SYS_DBAT3U@h
 	ori	r3, r3, CFG_SYS_DBAT3U@l
 	mtspr	DBAT3L, r4
 	mtspr	DBAT3U, r3
 
 #ifdef CONFIG_HIGH_BATS
 	/* IBAT 4 */
-	addis   r4, r0, CFG_SYS_IBAT4L@h
+	addis   r4,  0, CFG_SYS_IBAT4L@h
 	ori     r4, r4, CFG_SYS_IBAT4L@l
-	addis   r3, r0, CFG_SYS_IBAT4U@h
+	addis   r3,  0, CFG_SYS_IBAT4U@h
 	ori     r3, r3, CFG_SYS_IBAT4U@l
 	mtspr   IBAT4L, r4
 	mtspr   IBAT4U, r3
 
 	/* DBAT 4 */
-	addis   r4, r0, CFG_SYS_DBAT4L@h
+	addis   r4,  0, CFG_SYS_DBAT4L@h
 	ori     r4, r4, CFG_SYS_DBAT4L@l
-	addis   r3, r0, CFG_SYS_DBAT4U@h
+	addis   r3,  0, CFG_SYS_DBAT4U@h
 	ori     r3, r3, CFG_SYS_DBAT4U@l
 	mtspr   DBAT4L, r4
 	mtspr   DBAT4U, r3
 
 	/* IBAT 5 */
-	addis   r4, r0, CFG_SYS_IBAT5L@h
+	addis   r4,  0, CFG_SYS_IBAT5L@h
 	ori     r4, r4, CFG_SYS_IBAT5L@l
-	addis   r3, r0, CFG_SYS_IBAT5U@h
+	addis   r3,  0, CFG_SYS_IBAT5U@h
 	ori     r3, r3, CFG_SYS_IBAT5U@l
 	mtspr   IBAT5L, r4
 	mtspr   IBAT5U, r3
 
 	/* DBAT 5 */
-	addis   r4, r0, CFG_SYS_DBAT5L@h
+	addis   r4,  0, CFG_SYS_DBAT5L@h
 	ori     r4, r4, CFG_SYS_DBAT5L@l
-	addis   r3, r0, CFG_SYS_DBAT5U@h
+	addis   r3,  0, CFG_SYS_DBAT5U@h
 	ori     r3, r3, CFG_SYS_DBAT5U@l
 	mtspr   DBAT5L, r4
 	mtspr   DBAT5U, r3
 
 	/* IBAT 6 */
-	addis   r4, r0, CFG_SYS_IBAT6L@h
+	addis   r4,  0, CFG_SYS_IBAT6L@h
 	ori     r4, r4, CFG_SYS_IBAT6L@l
-	addis   r3, r0, CFG_SYS_IBAT6U@h
+	addis   r3,  0, CFG_SYS_IBAT6U@h
 	ori     r3, r3, CFG_SYS_IBAT6U@l
 	mtspr   IBAT6L, r4
 	mtspr   IBAT6U, r3
 
 	/* DBAT 6 */
-	addis   r4, r0, CFG_SYS_DBAT6L@h
+	addis   r4,  0, CFG_SYS_DBAT6L@h
 	ori     r4, r4, CFG_SYS_DBAT6L@l
-	addis   r3, r0, CFG_SYS_DBAT6U@h
+	addis   r3,  0, CFG_SYS_DBAT6U@h
 	ori     r3, r3, CFG_SYS_DBAT6U@l
 	mtspr   DBAT6L, r4
 	mtspr   DBAT6U, r3
 
 	/* IBAT 7 */
-	addis   r4, r0, CFG_SYS_IBAT7L@h
+	addis   r4,  0, CFG_SYS_IBAT7L@h
 	ori     r4, r4, CFG_SYS_IBAT7L@l
-	addis   r3, r0, CFG_SYS_IBAT7U@h
+	addis   r3,  0, CFG_SYS_IBAT7U@h
 	ori     r3, r3, CFG_SYS_IBAT7U@l
 	mtspr   IBAT7L, r4
 	mtspr   IBAT7U, r3
 
 	/* DBAT 7 */
-	addis   r4, r0, CFG_SYS_DBAT7L@h
+	addis   r4,  0, CFG_SYS_DBAT7L@h
 	ori     r4, r4, CFG_SYS_DBAT7L@l
-	addis   r3, r0, CFG_SYS_DBAT7U@h
+	addis   r3,  0, CFG_SYS_DBAT7U@h
 	ori     r3, r3, CFG_SYS_DBAT7U@l
 	mtspr   DBAT7L, r4
 	mtspr   DBAT7U, r3
@@ -1057,7 +1057,7 @@ lock_ram_in_cache:
 		     (CFG_SYS_INIT_RAM_ADDR & 31) + 31) / 32
 	mtctr	r4
 1:
-	dcbz	r0, r3
+	dcbz	0, r3
 	addi	r3, r3, 32
 	bdnz	1b
 
@@ -1078,8 +1078,8 @@ unlock_ram_in_cache:
 	li	r4, ((CFG_SYS_INIT_RAM_SIZE & ~31) + \
 		     (CFG_SYS_INIT_RAM_ADDR & 31) + 31) / 32
 	mtctr	r4
-1:	icbi	r0, r3
-	dcbi	r0, r3
+1:	icbi	0, r3
+	dcbi	0, r3
 	addi	r3, r3, 32
 	bdnz	1b
 	sync			/* Wait for all icbi to complete on bus	*/
diff --git a/arch/powerpc/cpu/mpc85xx/start.S b/arch/powerpc/cpu/mpc85xx/start.S
index 89bce5bed693e47f09015c0f50de9176e17badc1..5234e42dc28b1ff4ea7f003aee2ee8bb5bc2cf65 100644
--- a/arch/powerpc/cpu/mpc85xx/start.S
+++ b/arch/powerpc/cpu/mpc85xx/start.S
@@ -1203,12 +1203,12 @@ switch_as:
 	mtctr	r2
 	li	r0,0
 1:
-	dcbz	r0,r3
+	dcbz	0,r3
 #ifdef CONFIG_E6500	/* Lock/unlock L2 cache long with L1 */
-	dcbtls	2, r0, r3
-	dcbtls	0, r0, r3
+	dcbtls	2, 0, r3
+	dcbtls	0, 0, r3
 #else
-	dcbtls	0, r0, r3
+	dcbtls	0, 0, r3
 #endif
 	addi	r3,r3,CONFIG_SYS_CACHELINE_SIZE
 	bdnz	1b
@@ -1514,7 +1514,7 @@ out16:
 /*------------------------------------------------------------------------------- */
 	.globl	out16r
 out16r:
-	sthbrx	r4,r0,r3
+	sthbrx	r4,0,r3
 	sync
 	blr
 
@@ -1534,7 +1534,7 @@ out32:
 /*------------------------------------------------------------------------------- */
 	.globl	out32r
 out32r:
-	stwbrx	r4,r0,r3
+	stwbrx	r4,0,r3
 	sync
 	blr
 
@@ -1553,7 +1553,7 @@ in16:
 /*------------------------------------------------------------------------------- */
 	.globl	in16r
 in16r:
-	lhbrx	r3,r0,r3
+	lhbrx	r3,0,r3
 	blr
 
 /*------------------------------------------------------------------------------- */
@@ -1571,7 +1571,7 @@ in32:
 /*------------------------------------------------------------------------------- */
 	.globl	in32r
 in32r:
-	lwbrx	r3,r0,r3
+	lwbrx	r3,0,r3
 	blr
 #endif  /* !MINIMAL_SPL */
 
@@ -1832,12 +1832,12 @@ unlock_ram_in_cache:
 	andi.	r4,r4,0x1ff
 	slwi	r4,r4,(10 - 1 - L1_CACHE_SHIFT)
 	mtctr	r4
-1:	dcbi	r0,r3
+1:	dcbi	0,r3
 #ifdef CONFIG_E6500	/* lock/unlock L2 cache long with L1 */
-	dcblc	2, r0, r3
-	dcblc	0, r0, r3
+	dcblc	2, 0, r3
+	dcblc	0, 0, r3
 #else
-	dcblc	r0,r3
+	dcblc	0,r3
 #endif
 	addi	r3,r3,CONFIG_SYS_CACHELINE_SIZE
 	bdnz	1b
diff --git a/arch/powerpc/lib/ppccache.S b/arch/powerpc/lib/ppccache.S
index e55025181f76fd4b9bdef79db46ddea29c049b99..e94b40ead63d83dab0403ef842f281ddd50bb7ea 100644
--- a/arch/powerpc/lib/ppccache.S
+++ b/arch/powerpc/lib/ppccache.S
@@ -20,7 +20,7 @@
 /*------------------------------------------------------------------------------- */
 	.globl	ppcDcbf
 ppcDcbf:
-	dcbf	r0,r3
+	dcbf	0,r3
 	blr
 
 /*------------------------------------------------------------------------------- */
@@ -31,7 +31,7 @@ ppcDcbf:
 /*------------------------------------------------------------------------------- */
 	.globl	ppcDcbi
 ppcDcbi:
-	dcbi	r0,r3
+	dcbi	0,r3
 	blr
 
 /*--------------------------------------------------------------------------
@@ -43,7 +43,7 @@ ppcDcbi:
 
 	.globl	ppcDcbz
 ppcDcbz:
-	dcbz	r0,r3
+	dcbz	0,r3
 	blr
 
 /*------------------------------------------------------------------------------- */

-- 
2.45.2

