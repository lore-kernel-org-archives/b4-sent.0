From: Matt Thompson <matt@boondocker.io>
Date: Fri, 13 Nov 2026 17:28:50 -0700
Subject: [PATCH RFC 2/3] arm64: Allow synchronous abort fixups for guarded
 MMIO reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-rfc-b4-v1-2-b91dcb502250@boondocker.io>
References: <20261113-rfc-b4-v1-0-b91dcb502250@boondocker.io>
In-Reply-To: <20261113-rfc-b4-v1-0-b91dcb502250@boondocker.io>
To: Shawn Lin <shawn.lin@rock-chips.com>, 
 Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 linux-pci@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794616129; l=3185;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=+Rysg52MQ+WEH6U9bLqWMjonnyRMjgwZRj3Gm/L1z2c=;
 b=ivVIwpe9aQT6YH1SgFrUGUyAEZu4oOmIHxxnVxegwaq4g31oxKOagJc5lROvzRq9fuKPwg4vx
 yF+wEx3J69hCEMKYrIWpInK/vgWmpsDqq5yoGfMy5rE5sN+BOPEvhcR
X-Developer-Key: i=matt@boondocker.io; a=ed25519;
 pk=WMnh3kwFFRkrqamL/FbDcdl1/9rBF2uT03VdvGGP40k=
X-Endpoint-Received: by B4 Relay for matt@boondocker.io/rk3399-rfc-20261113 with auth_id=1517
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

An RK3399 PCI configuration read can raise a synchronous external data
abort if it does not get a usable response. Allow an explicitly annotated
MMIO load to return an error in this case.

Match only a current-EL synchronous external abort on a read instruction
with the new exception table type. Keep existing handling for other
faults, including asynchronous SError and translation table walk aborts.

Signed-off-by: Matt Thompson <matt@boondocker.io>
---
 arch/arm64/include/asm/asm-extable.h |  9 +++++++++
 arch/arm64/mm/extable.c              |  1 +
 arch/arm64/mm/fault.c                | 11 +++++++++++
 3 files changed, 21 insertions(+)

diff --git a/arch/arm64/include/asm/asm-extable.h b/arch/arm64/include/asm/asm-extable.h
index d67e2fd..ed80aec 100644
--- a/arch/arm64/include/asm/asm-extable.h
+++ b/arch/arm64/include/asm/asm-extable.h
@@ -11,6 +11,7 @@
 #define EX_TYPE_KACCESS_ERR_ZERO	3
 #define EX_TYPE_UACCESS_CPY		4
 #define EX_TYPE_LOAD_UNALIGNED_ZEROPAD	5
+#define EX_TYPE_MMIO_READ_ERR_ZERO	6
 
 /* Data fields for EX_TYPE_UACCESS_ERR_ZERO */
 #define EX_DATA_REG_ERR_SHIFT	0
@@ -123,6 +124,14 @@
 #define _ASM_EXTABLE_KACCESS(insn, fixup)				\
 	_ASM_EXTABLE_KACCESS_ERR_ZERO(insn, fixup, wzr, wzr)
 
+#define _ASM_EXTABLE_MMIO_READ_ERR_ZERO(insn, fixup, err, zero)		\
+	__ASM_EXTABLE_RAW(insn, fixup,					\
+			  __stringify(EX_TYPE_MMIO_READ_ERR_ZERO),	\
+			  "((.L__gpr_num_" err " << "			\
+			  __stringify(EX_DATA_REG_ERR_SHIFT) ") | "	\
+			  "(.L__gpr_num_" zero " << "			\
+			  __stringify(EX_DATA_REG_ZERO_SHIFT) "))")
+
 #define _ASM_EXTABLE_LOAD_UNALIGNED_ZEROPAD(insn, fixup, data, addr)		\
 	__DEFINE_ASM_GPR_NUMS							\
 	__ASM_EXTABLE_RAW(#insn, #fixup,					\
diff --git a/arch/arm64/mm/extable.c b/arch/arm64/mm/extable.c
index 299a244..c9b5944 100644
--- a/arch/arm64/mm/extable.c
+++ b/arch/arm64/mm/extable.c
@@ -100,6 +100,7 @@ bool fixup_exception(struct pt_regs *regs, unsigned long esr)
 		return ex_handler_bpf(ex, regs);
 	case EX_TYPE_UACCESS_ERR_ZERO:
 	case EX_TYPE_KACCESS_ERR_ZERO:
+	case EX_TYPE_MMIO_READ_ERR_ZERO:
 		return ex_handler_uaccess_err_zero(ex, regs);
 	case EX_TYPE_UACCESS_CPY:
 		return ex_handler_uaccess_cpy(ex, regs, esr);
diff --git a/arch/arm64/mm/fault.c b/arch/arm64/mm/fault.c
index b227368..148f7c9 100644
--- a/arch/arm64/mm/fault.c
+++ b/arch/arm64/mm/fault.c
@@ -877,8 +877,19 @@ static int do_bad(unsigned long far, unsigned long esr, struct pt_regs *regs)
 static int do_sea(unsigned long far, unsigned long esr, struct pt_regs *regs)
 {
 	const struct fault_info *inf;
+	const struct exception_table_entry *ex;
 	unsigned long siaddr;
 
+	/* Only a synchronous data abort on an explicitly guarded MMIO read. */
+	if (ESR_ELx_EC(esr) == ESR_ELx_EC_DABT_CUR &&
+	    (esr & ESR_ELx_FSC) == ESR_ELx_FSC_EXTABT &&
+	    !(esr & ESR_ELx_WNR)) {
+		ex = search_exception_tables(instruction_pointer(regs));
+		if (ex && ex->type == EX_TYPE_MMIO_READ_ERR_ZERO &&
+		    fixup_exception(regs, esr))
+			return 0;
+	}
+
 	inf = esr_to_fault_info(esr);
 
 	if (user_mode(regs) && apei_claim_sea(regs) == 0) {

-- 
Git-155)

