From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Sun, 21 Jun 2026 21:01:25 -0700
Subject: [PATCH v2 07/16] riscv: Use generated instruction headers for
 misaligned loads/stores
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260621-riscv_insn_table-v2-7-7f0810ee2274@gmail.com>
References: <20260621-riscv_insn_table-v2-0-7f0810ee2274@gmail.com>
In-Reply-To: <20260621-riscv_insn_table-v2-0-7f0810ee2274@gmail.com>
To: Paul Walmsley <pjw@kernel.org>, Palmer Dabbelt <palmer@dabbelt.com>, 
 Nam Cao <namcao@linutronix.de>, Alexandre Ghiti <alex@ghiti.fr>, 
 Anup Patel <anup@brainfault.org>, Atish Patra <atish.patra@linux.dev>, 
 Conor Dooley <conor@kernel.org>, Paolo Bonzini <pbonzini@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, Shuah Khan <shuah@kernel.org>, 
 =?utf-8?q?Radim_Kr=C4=8Dm=C3=A1=C5=99?= <radim.krcmar@oss.qualcomm.com>
Cc: linux-riscv@lists.infradead.org, linux-kernel@vger.kernel.org, 
 kvm@vger.kernel.org, kvm-riscv@lists.infradead.org, 
 linux-kselftest@vger.kernel.org, 
 Charlie Jenkins <thecharlesjenkins@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=12714;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=ZAiLZFKdSr+pr2o3OBlX9XLjRZtoG/b8FwQl9m8qk5Y=;
 b=y7IVZIEmcoljWJ93+YDaiUC+saBrOzoRz/XrCAyavNyO5zSoQSRFnaLkIZOJi0JJBm15P69lU
 Domxcx36VgcAuc5RmVVDjS7l9pp/yTkT62qaIugZmhW37lekgm4fYbd
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the misaligned loads/store code to use the generated instruction
headers instead of the hand-written instruction composition functions.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>

---

Similar to the other patches of this series, I extracted out the logic
of this function and brute forced all possible inputs to validate that
the outputs are the same. To verify this change in the kernel, I booted
on Spike and used the misaligned access checker which does some
misaligned accesses.
---
 arch/riscv/kernel/traps_misaligned.c | 183 ++++++++++++++++-------------------
 1 file changed, 83 insertions(+), 100 deletions(-)

diff --git a/arch/riscv/kernel/traps_misaligned.c b/arch/riscv/kernel/traps_misaligned.c
index 81b7682e6c6d..4d2a2432e0c4 100644
--- a/arch/riscv/kernel/traps_misaligned.c
+++ b/arch/riscv/kernel/traps_misaligned.c
@@ -22,15 +22,11 @@
 
 #ifdef CONFIG_FPU
 
-#define FP_GET_RD(insn)		(insn >> 7 & 0x1F)
-
 extern void put_f32_reg(unsigned long fp_reg, unsigned long value);
 
-static int set_f32_rd(unsigned long insn, struct pt_regs *regs,
+static int set_f32_rd(unsigned long fp_reg, struct pt_regs *regs,
 		      unsigned long val)
 {
-	unsigned long fp_reg = FP_GET_RD(insn);
-
 	put_f32_reg(fp_reg, val);
 	regs->status |= SR_FS_DIRTY;
 
@@ -39,9 +35,8 @@ static int set_f32_rd(unsigned long insn, struct pt_regs *regs,
 
 extern void put_f64_reg(unsigned long fp_reg, unsigned long value);
 
-static int set_f64_rd(unsigned long insn, struct pt_regs *regs, u64 val)
+static int set_f64_rd(unsigned long fp_reg, struct pt_regs *regs, u64 val)
 {
-	unsigned long fp_reg = FP_GET_RD(insn);
 	unsigned long value;
 
 #if __riscv_xlen == 32
@@ -58,10 +53,8 @@ static int set_f64_rd(unsigned long insn, struct pt_regs *regs, u64 val)
 #if __riscv_xlen == 32
 extern void get_f64_reg(unsigned long fp_reg, u64 *value);
 
-static u64 get_f64_rs(unsigned long insn, u8 fp_reg_offset,
-		      struct pt_regs *regs)
+static u64 get_f64_rs(unsigned long fp_reg, struct pt_regs *regs)
 {
-	unsigned long fp_reg = (insn >> fp_reg_offset) & 0x1F;
 	u64 val;
 
 	get_f64_reg(fp_reg, &val);
@@ -73,10 +66,8 @@ static u64 get_f64_rs(unsigned long insn, u8 fp_reg_offset,
 
 extern unsigned long get_f64_reg(unsigned long fp_reg);
 
-static unsigned long get_f64_rs(unsigned long insn, u8 fp_reg_offset,
-				struct pt_regs *regs)
+static unsigned long get_f64_rs(unsigned long fp_reg, struct pt_regs *regs)
 {
-	unsigned long fp_reg = (insn >> fp_reg_offset) & 0x1F;
 	unsigned long val;
 
 	val = get_f64_reg(fp_reg);
@@ -89,10 +80,8 @@ static unsigned long get_f64_rs(unsigned long insn, u8 fp_reg_offset,
 
 extern unsigned long get_f32_reg(unsigned long fp_reg);
 
-static unsigned long get_f32_rs(unsigned long insn, u8 fp_reg_offset,
-				struct pt_regs *regs)
+static unsigned long get_f32_rs(unsigned long fp_reg, struct pt_regs *regs)
 {
-	unsigned long fp_reg = (insn >> fp_reg_offset) & 0x1F;
 	unsigned long val;
 
 	val = get_f32_reg(fp_reg);
@@ -107,28 +96,18 @@ static void set_f32_rd(unsigned long insn, struct pt_regs *regs,
 
 static void set_f64_rd(unsigned long insn, struct pt_regs *regs, u64 val) {}
 
-static unsigned long get_f64_rs(unsigned long insn, u8 fp_reg_offset,
-				struct pt_regs *regs)
+static unsigned long get_f64_rs(unsigned long fp_reg, struct pt_regs *regs)
 {
 	return 0;
 }
 
-static unsigned long get_f32_rs(unsigned long insn, u8 fp_reg_offset,
-				struct pt_regs *regs)
+static unsigned long get_f32_rs(unsigned long fp_reg, struct pt_regs *regs)
 {
 	return 0;
 }
 
 #endif
 
-#define GET_F64_RS2(insn, regs) (get_f64_rs(insn, 20, regs))
-#define GET_F64_RS2C(insn, regs) (get_f64_rs(insn, 2, regs))
-#define GET_F64_RS2S(insn, regs) (get_f64_rs(RVC_RS2S(insn), 0, regs))
-
-#define GET_F32_RS2(insn, regs) (get_f32_rs(insn, 20, regs))
-#define GET_F32_RS2C(insn, regs) (get_f32_rs(insn, 2, regs))
-#define GET_F32_RS2S(insn, regs) (get_f32_rs(RVC_RS2S(insn), 0, regs))
-
 #define __read_insn(regs, insn, insn_addr, type)	\
 ({							\
 	int __ret;					\
@@ -217,13 +196,13 @@ static int handle_vector_misaligned_load(struct pt_regs *regs)
 }
 #endif
 
-static int handle_scalar_misaligned_load(struct pt_regs *regs)
+static noinline int handle_scalar_misaligned_load(struct pt_regs *regs)
 {
 	union reg_data val;
 	unsigned long epc = regs->epc;
 	unsigned long insn;
 	unsigned long addr = regs->badaddr;
-	int fp = 0, shift = 0, len = 0;
+	int fp = 0, shift = 0, len = 0, rd = 0;
 
 	perf_sw_event(PERF_COUNT_SW_ALIGNMENT_FAULTS, 1, regs, addr);
 
@@ -240,68 +219,71 @@ static int handle_scalar_misaligned_load(struct pt_regs *regs)
 
 	regs->epc = 0;
 
-	if ((insn & INSN_MASK_LW) == INSN_MATCH_LW) {
+	if (riscv_insn_is_lw(insn)) {
 		len = 4;
 		shift = 8 * (sizeof(unsigned long) - len);
-#if defined(CONFIG_64BIT)
-	} else if ((insn & INSN_MASK_LD) == INSN_MATCH_LD) {
+		rd = riscv_insn_lw_extract_xd(insn);
+	} else if (riscv_insn_is_ld(insn)) {
 		len = 8;
 		shift = 8 * (sizeof(unsigned long) - len);
-	} else if ((insn & INSN_MASK_LWU) == INSN_MATCH_LWU) {
+		rd = riscv_insn_ld_extract_xd(insn);
+	} else if (riscv_insn_is_lwu(insn)) {
 		len = 4;
-#endif
-	} else if ((insn & INSN_MASK_FLD) == INSN_MATCH_FLD) {
+		rd = riscv_insn_lwu_extract_xd(insn);
+	} else if (riscv_insn_is_fld(insn)) {
 		fp = 1;
 		len = 8;
-	} else if ((insn & INSN_MASK_FLW) == INSN_MATCH_FLW) {
+		rd = riscv_insn_fld_extract_fd(insn);
+	} else if (riscv_insn_is_flw(insn)) {
 		fp = 1;
 		len = 4;
-	} else if ((insn & INSN_MASK_LH) == INSN_MATCH_LH) {
+		rd = riscv_insn_flw_extract_fd(insn);
+	} else if (riscv_insn_is_lh(insn)) {
 		len = 2;
 		shift = 8 * (sizeof(unsigned long) - len);
-	} else if ((insn & INSN_MASK_LHU) == INSN_MATCH_LHU) {
+		rd = riscv_insn_lh_extract_xd(insn);
+	} else if (riscv_insn_is_lhu(insn)) {
 		len = 2;
-#if defined(CONFIG_64BIT)
-	} else if ((insn & INSN_MASK_C_LD) == INSN_MATCH_C_LD) {
+		rd = riscv_insn_lhu_extract_xd(insn);
+	} else if (riscv_insn_is_c_ld(insn)) {
 		len = 8;
 		shift = 8 * (sizeof(unsigned long) - len);
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_LDSP) == INSN_MATCH_C_LDSP &&
-		   ((insn >> SH_RD) & 0x1f)) {
+		rd = (8 + riscv_insn_c_ld_extract_xd(insn));
+	} else if (riscv_insn_is_c_ldsp(insn)) {
 		len = 8;
 		shift = 8 * (sizeof(unsigned long) - len);
-#endif
-	} else if ((insn & INSN_MASK_C_LW) == INSN_MATCH_C_LW) {
+		rd = riscv_insn_c_ldsp_extract_xd(insn);
+	} else if (riscv_insn_is_c_lw(insn)) {
 		len = 4;
 		shift = 8 * (sizeof(unsigned long) - len);
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_LWSP) == INSN_MATCH_C_LWSP &&
-		   ((insn >> SH_RD) & 0x1f)) {
+		rd = (8 + riscv_insn_c_lw_extract_xd(insn));
+	} else if (riscv_insn_is_c_lwsp(insn)) {
 		len = 4;
 		shift = 8 * (sizeof(unsigned long) - len);
-	} else if ((insn & INSN_MASK_C_FLD) == INSN_MATCH_C_FLD) {
+		rd = riscv_insn_c_lwsp_extract_xd(insn);
+	} else if (riscv_insn_is_c_fld(insn)) {
 		fp = 1;
 		len = 8;
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_FLDSP) == INSN_MATCH_C_FLDSP) {
+		rd = (8 + riscv_insn_c_fld_extract_fd(insn));
+	} else if (riscv_insn_is_c_fldsp(insn)) {
 		fp = 1;
 		len = 8;
-#if defined(CONFIG_32BIT)
-	} else if ((insn & INSN_MASK_C_FLW) == INSN_MATCH_C_FLW) {
+		rd = riscv_insn_c_fldsp_extract_fd(insn);
+	} else if (riscv_insn_is_c_flw(insn)) {
 		fp = 1;
 		len = 4;
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_FLWSP) == INSN_MATCH_C_FLWSP) {
+		rd = (8 + riscv_insn_c_flw_extract_fd(insn));
+	} else if (riscv_insn_is_c_flwsp(insn)) {
 		fp = 1;
 		len = 4;
-#endif
-	} else if ((insn & INSN_MASK_C_LHU) == INSN_MATCH_C_LHU) {
+		rd = riscv_insn_c_flwsp_extract_fd(insn);
+	} else if (riscv_insn_is_c_lhu(insn)) {
 		len = 2;
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_LH) == INSN_MATCH_C_LH) {
+		rd = (8 + riscv_insn_c_lhu_extract_xd(insn));
+	} else if (riscv_insn_is_c_lh(insn)) {
 		len = 2;
-		shift = 8 * (sizeof(ulong) - len);
-		insn = RVC_RS2S(insn) << SH_RD;
+		shift = 8 * (sizeof(unsigned long) - len);
+		rd = (8 + riscv_insn_c_lh_extract_xd(insn));
 	} else {
 		regs->epc = epc;
 		return -1;
@@ -319,11 +301,11 @@ static int handle_scalar_misaligned_load(struct pt_regs *regs)
 	}
 
 	if (!fp)
-		SET_RD(insn, regs, (long)(val.data_ulong << shift) >> shift);
+		*(unsigned long *)((unsigned long *)regs + rd) = val.data_ulong << shift;
 	else if (len == 8)
-		set_f64_rd(insn, regs, val.data_u64);
+		set_f64_rd(rd, regs, val.data_u64);
 	else
-		set_f32_rd(insn, regs, val.data_ulong);
+		set_f32_rd(rd, regs, val.data_ulong);
 
 	regs->epc = epc + INSN_LEN(insn);
 
@@ -336,7 +318,7 @@ static int handle_scalar_misaligned_store(struct pt_regs *regs)
 	unsigned long epc = regs->epc;
 	unsigned long insn;
 	unsigned long addr = regs->badaddr;
-	int len = 0, fp = 0;
+	int fp = 0, len = 0, rd = 0;
 
 	perf_sw_event(PERF_COUNT_SW_ALIGNMENT_FAULTS, 1, regs, addr);
 
@@ -351,67 +333,68 @@ static int handle_scalar_misaligned_store(struct pt_regs *regs)
 
 	regs->epc = 0;
 
-	val.data_ulong = GET_RS2(insn, regs);
-
-	if ((insn & INSN_MASK_SW) == INSN_MATCH_SW) {
+	if (riscv_insn_is_sw(insn)) {
 		len = 4;
-#if defined(CONFIG_64BIT)
-	} else if ((insn & INSN_MASK_SD) == INSN_MATCH_SD) {
+		rd = riscv_insn_sw_extract_xs2(insn);
+	} else if (riscv_insn_is_sd(insn)) {
 		len = 8;
-#endif
-	} else if ((insn & INSN_MASK_FSD) == INSN_MATCH_FSD) {
+		rd = riscv_insn_sd_extract_xs2(insn);
+	} else if (riscv_insn_is_fsd(insn)) {
 		fp = 1;
 		len = 8;
-		val.data_u64 = GET_F64_RS2(insn, regs);
-	} else if ((insn & INSN_MASK_FSW) == INSN_MATCH_FSW) {
+		rd = riscv_insn_fsd_extract_fs2(insn);
+	} else if (riscv_insn_is_fsw(insn)) {
 		fp = 1;
 		len = 4;
-		val.data_ulong = GET_F32_RS2(insn, regs);
-	} else if ((insn & INSN_MASK_SH) == INSN_MATCH_SH) {
+		rd = riscv_insn_fsw_extract_fs2(insn);
+	} else if (riscv_insn_is_sh(insn)) {
 		len = 2;
-#if defined(CONFIG_64BIT)
-	} else if ((insn & INSN_MASK_C_SD) == INSN_MATCH_C_SD) {
+		rd = riscv_insn_sh_extract_xs2(insn);
+	} else if (riscv_insn_is_c_sd(insn)) {
 		len = 8;
-		val.data_ulong = GET_RS2S(insn, regs);
-	} else if ((insn & INSN_MASK_C_SDSP) == INSN_MATCH_C_SDSP) {
+		rd = riscv_insn_c_sd_extract_xs2(insn);
+	} else if (riscv_insn_is_c_sdsp(insn)) {
 		len = 8;
-		val.data_ulong = GET_RS2C(insn, regs);
-#endif
-	} else if ((insn & INSN_MASK_C_SW) == INSN_MATCH_C_SW) {
+		rd = riscv_insn_c_sdsp_extract_xs2(insn);
+	} else if (riscv_insn_is_c_sw(insn)) {
 		len = 4;
-		val.data_ulong = GET_RS2S(insn, regs);
-	} else if ((insn & INSN_MASK_C_SWSP) == INSN_MATCH_C_SWSP) {
+		rd = riscv_insn_c_sw_extract_xs2(insn);
+	} else if (riscv_insn_is_c_swsp(insn)) {
 		len = 4;
-		val.data_ulong = GET_RS2C(insn, regs);
-	} else if ((insn & INSN_MASK_C_FSD) == INSN_MATCH_C_FSD) {
+		rd = riscv_insn_c_swsp_extract_xs2(insn);
+	} else if (riscv_insn_is_c_fsd(insn)) {
 		fp = 1;
 		len = 8;
-		val.data_u64 = GET_F64_RS2S(insn, regs);
-	} else if ((insn & INSN_MASK_C_FSDSP) == INSN_MATCH_C_FSDSP) {
+		rd = riscv_insn_c_fsd_extract_fs2(insn);
+	} else if (riscv_insn_is_c_fsdsp(insn)) {
 		fp = 1;
 		len = 8;
-		val.data_u64 = GET_F64_RS2C(insn, regs);
-#if !defined(CONFIG_64BIT)
-	} else if ((insn & INSN_MASK_C_FSW) == INSN_MATCH_C_FSW) {
+		rd = riscv_insn_c_fsdsp_extract_fs2(insn);
+	} else if (riscv_insn_is_c_fsw(insn)) {
 		fp = 1;
 		len = 4;
-		val.data_ulong = GET_F32_RS2S(insn, regs);
-	} else if ((insn & INSN_MASK_C_FSWSP) == INSN_MATCH_C_FSWSP) {
+		rd = riscv_insn_c_fsw_extract_fs2(insn);
+	} else if (riscv_insn_is_c_fswsp(insn)) {
 		fp = 1;
 		len = 4;
-		val.data_ulong = GET_F32_RS2C(insn, regs);
-#endif
-	} else if ((insn & INSN_MASK_C_SH) == INSN_MATCH_C_SH) {
+		rd = riscv_insn_c_fswsp_extract_fs2(insn);
+	} else if (riscv_insn_is_c_sh(insn)) {
 		len = 2;
-		val.data_ulong = GET_RS2S(insn, regs);
+		rd = riscv_insn_c_sh_extract_xs2(insn);
 	} else {
-		regs->epc = epc;
 		return -1;
 	}
 
 	if (!IS_ENABLED(CONFIG_FPU) && fp)
 		return -EOPNOTSUPP;
 
+	if (!fp)
+		val.data_ulong = *(unsigned long *)((unsigned long *)regs + rd);
+	else if (len == 8)
+		val.data_u64 = get_f64_rs(rd, regs);
+	else
+		val.data_ulong = get_f32_rs(rd, regs);
+
 	if (user_mode(regs)) {
 		if (copy_to_user((u8 __user *)addr, &val, len))
 			return -1;

-- 
2.54.0

