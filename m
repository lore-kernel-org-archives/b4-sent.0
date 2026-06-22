From: Charlie Jenkins <thecharlesjenkins@gmail.com>
Date: Sun, 21 Jun 2026 21:01:29 -0700
Subject: [PATCH v2 11/16] riscv: kvm: Use generated instruction headers for
 mmio emulation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260621-riscv_insn_table-v2-11-7f0810ee2274@gmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782100900; l=8876;
 i=thecharlesjenkins@gmail.com; s=20260605; h=from:subject:message-id;
 bh=xLjfQQgbABuNv4NqoIYoQ0JwPk9sFvPpnVlBWBNYiFs=;
 b=hzZNb94V9q2yxNe3ri7V6qBvZdsHV+gyBSXdq6F7Y7ldcMvfqWufSkDWdCUyNaeh1VqVIpqJq
 Ih2tq/TWOemDNtQQKXUmVO3elI3safa90MkTU9UdNy8S7aZR4D7H8N2
X-Developer-Key: i=thecharlesjenkins@gmail.com; a=ed25519;
 pk=ajnnRQ98PIdwKp4HeMkq9U32okYbnh6Zb4G3o5XXvkg=
X-Endpoint-Received: by B4 Relay for thecharlesjenkins@gmail.com/20260605 with auth_id=810
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Migrate the mmio emulation code to use the generated instruction headers
instead of the hand-written instruction composition functions.

Signed-off-by: Charlie Jenkins <thecharlesjenkins@gmail.com>
---
 arch/riscv/include/asm/kvm_vcpu_insn.h |   2 +-
 arch/riscv/kvm/vcpu_insn.c             | 127 ++++++++++++++-------------------
 2 files changed, 55 insertions(+), 74 deletions(-)

diff --git a/arch/riscv/include/asm/kvm_vcpu_insn.h b/arch/riscv/include/asm/kvm_vcpu_insn.h
index 350011c83581..106fb4c45108 100644
--- a/arch/riscv/include/asm/kvm_vcpu_insn.h
+++ b/arch/riscv/include/asm/kvm_vcpu_insn.h
@@ -11,7 +11,7 @@ struct kvm_run;
 struct kvm_cpu_trap;
 
 struct kvm_mmio_decode {
-	unsigned long insn;
+	unsigned long rd;
 	int insn_len;
 	int len;
 	int shift;
diff --git a/arch/riscv/kvm/vcpu_insn.c b/arch/riscv/kvm/vcpu_insn.c
index 8ccf6ec722f0..1d8741d02242 100644
--- a/arch/riscv/kvm/vcpu_insn.c
+++ b/arch/riscv/kvm/vcpu_insn.c
@@ -376,7 +376,7 @@ int kvm_riscv_vcpu_mmio_load(struct kvm_vcpu *vcpu, struct kvm_run *run,
 			     unsigned long htinst)
 {
 	u8 data_buf[8];
-	unsigned long insn;
+	unsigned long insn, rd;
 	int shift = 0, len = 0, insn_len = 0;
 	struct kvm_cpu_trap utrap = { 0 };
 	struct kvm_cpu_context *ct = &vcpu->arch.guest_context;
@@ -408,44 +408,47 @@ int kvm_riscv_vcpu_mmio_load(struct kvm_vcpu *vcpu, struct kvm_run *run,
 	}
 
 	/* Decode length of MMIO and shift */
-	if ((insn & INSN_MASK_LW) == INSN_MATCH_LW) {
+	if (riscv_insn_is_lw(insn)) {
 		len = 4;
 		shift = 8 * (sizeof(ulong) - len);
-	} else if ((insn & INSN_MASK_LB) == INSN_MATCH_LB) {
+		rd = riscv_insn_lw_extract_xd(insn);
+	} else if (riscv_insn_is_lb(insn)) {
 		len = 1;
 		shift = 8 * (sizeof(ulong) - len);
-	} else if ((insn & INSN_MASK_LBU) == INSN_MATCH_LBU) {
+		rd = riscv_insn_lb_extract_xd(insn);
+	} else if (riscv_insn_is_lbu(insn)) {
 		len = 1;
-#ifdef CONFIG_64BIT
-	} else if ((insn & INSN_MASK_LD) == INSN_MATCH_LD) {
+		rd = riscv_insn_lbu_extract_xd(insn);
+	} else if (riscv_insn_is_ld(insn)) {
 		len = 8;
 		shift = 8 * (sizeof(ulong) - len);
-	} else if ((insn & INSN_MASK_LWU) == INSN_MATCH_LWU) {
+		rd = riscv_insn_ld_extract_xd(insn);
+	} else if (riscv_insn_is_lwu(insn)) {
 		len = 4;
-#endif
-	} else if ((insn & INSN_MASK_LH) == INSN_MATCH_LH) {
+		rd = riscv_insn_lwu_extract_xd(insn);
+	} else if (riscv_insn_is_lh(insn)) {
 		len = 2;
 		shift = 8 * (sizeof(ulong) - len);
-	} else if ((insn & INSN_MASK_LHU) == INSN_MATCH_LHU) {
+		rd = riscv_insn_lh_extract_xd(insn);
+	} else if (riscv_insn_is_lhu(insn)) {
 		len = 2;
-#ifdef CONFIG_64BIT
-	} else if ((insn & INSN_MASK_C_LD) == INSN_MATCH_C_LD) {
+		rd = riscv_insn_lhu_extract_xd(insn);
+	} else if (riscv_insn_is_c_ld(insn)) {
 		len = 8;
 		shift = 8 * (sizeof(ulong) - len);
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_LDSP) == INSN_MATCH_C_LDSP &&
-		   ((insn >> SH_RD) & 0x1f)) {
+		rd = riscv_insn_c_ld_extract_xd(insn);
+	} else if (riscv_insn_is_c_ldsp(insn)) {
 		len = 8;
 		shift = 8 * (sizeof(ulong) - len);
-#endif
-	} else if ((insn & INSN_MASK_C_LW) == INSN_MATCH_C_LW) {
+		rd = riscv_insn_c_ldsp_extract_xd(insn);
+	} else if (riscv_insn_is_c_lw(insn)) {
 		len = 4;
 		shift = 8 * (sizeof(ulong) - len);
-		insn = RVC_RS2S(insn) << SH_RD;
-	} else if ((insn & INSN_MASK_C_LWSP) == INSN_MATCH_C_LWSP &&
-		   ((insn >> SH_RD) & 0x1f)) {
+		rd = riscv_insn_c_lw_extract_xd(insn);
+	} else if (riscv_insn_is_c_lwsp(insn)) {
 		len = 4;
 		shift = 8 * (sizeof(ulong) - len);
+		rd = riscv_insn_c_lwsp_extract_xd(insn);
 	} else {
 		return -EOPNOTSUPP;
 	}
@@ -455,7 +458,7 @@ int kvm_riscv_vcpu_mmio_load(struct kvm_vcpu *vcpu, struct kvm_run *run,
 		return -EIO;
 
 	/* Save instruction decode info */
-	vcpu->arch.mmio_decode.insn = insn;
+	vcpu->arch.mmio_decode.rd = rd;
 	vcpu->arch.mmio_decode.insn_len = insn_len;
 	vcpu->arch.mmio_decode.shift = shift;
 	vcpu->arch.mmio_decode.len = len;
@@ -498,11 +501,7 @@ int kvm_riscv_vcpu_mmio_store(struct kvm_vcpu *vcpu, struct kvm_run *run,
 			      unsigned long fault_addr,
 			      unsigned long htinst)
 {
-	u8 data8;
-	u16 data16;
-	u32 data32;
-	u64 data64;
-	ulong data;
+	ulong data, rs2;
 	unsigned long insn;
 	int len = 0, insn_len = 0;
 	struct kvm_cpu_trap utrap = { 0 };
@@ -534,35 +533,30 @@ int kvm_riscv_vcpu_mmio_store(struct kvm_vcpu *vcpu, struct kvm_run *run,
 		insn_len = INSN_LEN(insn);
 	}
 
-	data = GET_RS2(insn, &vcpu->arch.guest_context);
-	data8 = data16 = data32 = data64 = data;
-
-	if ((insn & INSN_MASK_SW) == INSN_MATCH_SW) {
+	if (riscv_insn_is_sw(insn)) {
 		len = 4;
-	} else if ((insn & INSN_MASK_SB) == INSN_MATCH_SB) {
+		rs2 = riscv_insn_sw_extract_xs2(insn);
+	} else if (riscv_insn_is_sb(insn)) {
 		len = 1;
-#ifdef CONFIG_64BIT
-	} else if ((insn & INSN_MASK_SD) == INSN_MATCH_SD) {
+		rs2 = riscv_insn_sb_extract_xs2(insn);
+	} else if (riscv_insn_is_sd(insn)) {
 		len = 8;
-#endif
-	} else if ((insn & INSN_MASK_SH) == INSN_MATCH_SH) {
+		rs2 = riscv_insn_sd_extract_xs2(insn);
+	} else if (riscv_insn_is_sh(insn)) {
 		len = 2;
-#ifdef CONFIG_64BIT
-	} else if ((insn & INSN_MASK_C_SD) == INSN_MATCH_C_SD) {
+		rs2 = riscv_insn_sh_extract_xs2(insn);
+	} else if (riscv_insn_is_c_sd(insn)) {
 		len = 8;
-		data64 = GET_RS2S(insn, &vcpu->arch.guest_context);
-	} else if ((insn & INSN_MASK_C_SDSP) == INSN_MATCH_C_SDSP &&
-		   ((insn >> SH_RD) & 0x1f)) {
+		rs2 = riscv_insn_c_sd_extract_xs2(insn);
+	} else if (riscv_insn_is_c_sdsp(insn)) {
 		len = 8;
-		data64 = GET_RS2C(insn, &vcpu->arch.guest_context);
-#endif
-	} else if ((insn & INSN_MASK_C_SW) == INSN_MATCH_C_SW) {
+		rs2 = riscv_insn_c_sdsp_extract_xs2(insn);
+	} else if (riscv_insn_is_c_sw(insn)) {
 		len = 4;
-		data32 = GET_RS2S(insn, &vcpu->arch.guest_context);
-	} else if ((insn & INSN_MASK_C_SWSP) == INSN_MATCH_C_SWSP &&
-		   ((insn >> SH_RD) & 0x1f)) {
+		rs2 = riscv_insn_c_sw_extract_xs2(insn);
+	} else if (riscv_insn_is_c_swsp(insn)) {
 		len = 4;
-		data32 = GET_RS2C(insn, &vcpu->arch.guest_context);
+		rs2 = riscv_insn_c_swsp_extract_xs2(insn);
 	} else {
 		return -EOPNOTSUPP;
 	}
@@ -571,26 +565,24 @@ int kvm_riscv_vcpu_mmio_store(struct kvm_vcpu *vcpu, struct kvm_run *run,
 	if (fault_addr & (len - 1))
 		return -EIO;
 
-	/* Save instruction decode info */
-	vcpu->arch.mmio_decode.insn = insn;
 	vcpu->arch.mmio_decode.insn_len = insn_len;
-	vcpu->arch.mmio_decode.shift = 0;
-	vcpu->arch.mmio_decode.len = len;
 	vcpu->arch.mmio_decode.return_handled = 0;
 
+	data = *((ulong *)(&vcpu->arch.guest_context) + rs2);
+
 	/* Copy data to kvm_run instance */
 	switch (len) {
 	case 1:
-		*((u8 *)run->mmio.data) = data8;
+		*((u8 *)run->mmio.data) = data;
 		break;
 	case 2:
-		*((u16 *)run->mmio.data) = data16;
+		*((u16 *)run->mmio.data) = data;
 		break;
 	case 4:
-		*((u32 *)run->mmio.data) = data32;
+		*((u32 *)run->mmio.data) = data;
 		break;
 	case 8:
-		*((u64 *)run->mmio.data) = data64;
+		*((u64 *)run->mmio.data) = data;
 		break;
 	default:
 		return -EOPNOTSUPP;
@@ -626,18 +618,13 @@ int kvm_riscv_vcpu_mmio_store(struct kvm_vcpu *vcpu, struct kvm_run *run,
  */
 int kvm_riscv_vcpu_mmio_return(struct kvm_vcpu *vcpu, struct kvm_run *run)
 {
-	u8 data8;
-	u16 data16;
-	u32 data32;
-	u64 data64;
-	ulong insn;
 	int len, shift;
+	unsigned long data;
 
 	if (vcpu->arch.mmio_decode.return_handled)
 		return 0;
 
 	vcpu->arch.mmio_decode.return_handled = 1;
-	insn = vcpu->arch.mmio_decode.insn;
 
 	if (run->mmio.is_write)
 		goto done;
@@ -647,29 +634,23 @@ int kvm_riscv_vcpu_mmio_return(struct kvm_vcpu *vcpu, struct kvm_run *run)
 
 	switch (len) {
 	case 1:
-		data8 = *((u8 *)run->mmio.data);
-		SET_RD(insn, &vcpu->arch.guest_context,
-			(long)((ulong)data8 << shift) >> shift);
+		data = *((u8 *)run->mmio.data);
 		break;
 	case 2:
-		data16 = *((u16 *)run->mmio.data);
-		SET_RD(insn, &vcpu->arch.guest_context,
-			(long)((ulong)data16 << shift) >> shift);
+		data = *((u16 *)run->mmio.data);
 		break;
 	case 4:
-		data32 = *((u32 *)run->mmio.data);
-		SET_RD(insn, &vcpu->arch.guest_context,
-			(long)((ulong)data32 << shift) >> shift);
+		data = *((u32 *)run->mmio.data);
 		break;
 	case 8:
-		data64 = *((u64 *)run->mmio.data);
-		SET_RD(insn, &vcpu->arch.guest_context,
-			(long)((ulong)data64 << shift) >> shift);
+		data = *((u64 *)run->mmio.data);
 		break;
 	default:
 		return -EOPNOTSUPP;
 	}
 
+	*((ulong *)(&vcpu->arch.guest_context) + vcpu->arch.mmio_decode.rd) =
+		(long)data << shift >> shift;
 done:
 	/* Move to next instruction */
 	vcpu->arch.guest_context.sepc += vcpu->arch.mmio_decode.insn_len;

-- 
2.54.0

