From: Matt Thompson <matt@boondocker.io>
Date: Fri, 13 Nov 2026 17:52:20 -0700
Subject: [PATCH RFC v2 2/3] arm64: Allow synchronous abort fixups for
 guarded MMIO reads
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-rfc-b4-v2-2-d6b14f95c1d6@boondocker.io>
References: <20261113-rfc-b4-v2-0-d6b14f95c1d6@boondocker.io>
In-Reply-To: <20261113-rfc-b4-v2-0-d6b14f95c1d6@boondocker.io>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794617540; l=3957;
 i=matt@boondocker.io; s=rk3399-rfc-20261113; h=from:subject:message-id;
 bh=O2LbMV/iAQG9voycLpkvTk5xx5a7660O6hR4aIZ4gWk=;
 b=AOyjADqb2c9zoTvOxoesEqPq2yFWtk+fGp4f0dFjGUBjgacjGBHN2o1QsuuE7wEmK2y/dvjeQ
 0Bj55wz2NCVAGOBG3u4H5pEBc9Gt7IU9E3dA1lwhdo+WnxAxk+nSbxI
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
 arch/arm64/include/asm/asm-extable.h | 15 +++++++++++++++
 arch/arm64/mm/extable.c              | 20 ++++++++++++++++++++
 arch/arm64/mm/fault.c                |  4 ++++
 3 files changed, 39 insertions(+)

diff --git a/arch/arm64/include/asm/asm-extable.h b/arch/arm64/include/asm/asm-extable.h
index d67e2fd..ac78167 100644
--- a/arch/arm64/include/asm/asm-extable.h
+++ b/arch/arm64/include/asm/asm-extable.h
@@ -11,6 +11,7 @@
 #define EX_TYPE_KACCESS_ERR_ZERO	3
 #define EX_TYPE_UACCESS_CPY		4
 #define EX_TYPE_LOAD_UNALIGNED_ZEROPAD	5
+#define EX_TYPE_MMIO_READ_ERR_ZERO	6
 
 /* Data fields for EX_TYPE_UACCESS_ERR_ZERO */
 #define EX_DATA_REG_ERR_SHIFT	0
@@ -80,6 +81,11 @@
 #else /* __ASSEMBLER__ */
 
 #include <linux/stringify.h>
+#include <linux/types.h>
+
+struct pt_regs;
+
+bool fixup_sea_exception(struct pt_regs *regs, unsigned long esr);
 
 #define __ASM_EXTABLE_RAW(insn, fixup, type, data)	\
 	".pushsection	__ex_table, \"a\"\n"		\
@@ -111,6 +117,15 @@
 			    EX_DATA_REG(ZERO, zero)			\
 			  ")")
 
+#define _ASM_EXTABLE_MMIO_READ_ERR_ZERO(insn, fixup, err, zero)		\
+	__DEFINE_ASM_GPR_NUMS						\
+	__ASM_EXTABLE_RAW(#insn, #fixup,				\
+			  __stringify(EX_TYPE_MMIO_READ_ERR_ZERO),	\
+			  "("						\
+			    EX_DATA_REG(ERR, err) " | "			\
+			    EX_DATA_REG(ZERO, zero)			\
+			  ")")
+
 #define _ASM_EXTABLE_UACCESS_ERR(insn, fixup, err)			\
 	_ASM_EXTABLE_UACCESS_ERR_ZERO(insn, fixup, err, wzr)
 
diff --git a/arch/arm64/mm/extable.c b/arch/arm64/mm/extable.c
index 299a244..dcb84d8 100644
--- a/arch/arm64/mm/extable.c
+++ b/arch/arm64/mm/extable.c
@@ -28,6 +28,8 @@ bool insn_may_access_user(unsigned long addr, unsigned long esr)
 		return false;
 
 	switch (ex->type) {
+	case EX_TYPE_MMIO_READ_ERR_ZERO:
+		return false;
 	case EX_TYPE_UACCESS_CPY:
 		return cpy_faulted_on_uaccess(ex, esr);
 	default:
@@ -101,6 +103,8 @@ bool fixup_exception(struct pt_regs *regs, unsigned long esr)
 	case EX_TYPE_UACCESS_ERR_ZERO:
 	case EX_TYPE_KACCESS_ERR_ZERO:
 		return ex_handler_uaccess_err_zero(ex, regs);
+	case EX_TYPE_MMIO_READ_ERR_ZERO:
+		return false;
 	case EX_TYPE_UACCESS_CPY:
 		return ex_handler_uaccess_cpy(ex, regs, esr);
 	case EX_TYPE_LOAD_UNALIGNED_ZEROPAD:
@@ -109,3 +113,19 @@ bool fixup_exception(struct pt_regs *regs, unsigned long esr)
 
 	BUG();
 }
+
+bool fixup_sea_exception(struct pt_regs *regs, unsigned long esr)
+{
+	const struct exception_table_entry *ex;
+
+	if (ESR_ELx_EC(esr) != ESR_ELx_EC_DABT_CUR ||
+	    (esr & ESR_ELx_FSC) != ESR_ELx_FSC_EXTABT ||
+	    (esr & ESR_ELx_WNR))
+		return false;
+
+	ex = search_exception_tables(instruction_pointer(regs));
+	if (!ex || ex->type != EX_TYPE_MMIO_READ_ERR_ZERO)
+		return false;
+
+	return ex_handler_uaccess_err_zero(ex, regs);
+}
diff --git a/arch/arm64/mm/fault.c b/arch/arm64/mm/fault.c
index b227368..ebe8054 100644
--- a/arch/arm64/mm/fault.c
+++ b/arch/arm64/mm/fault.c
@@ -30,6 +30,7 @@
 #include <linux/hugetlb.h>
 
 #include <asm/acpi.h>
+#include <asm/asm-extable.h>
 #include <asm/bug.h>
 #include <asm/cmpxchg.h>
 #include <asm/cpufeature.h>
@@ -879,6 +880,9 @@ static int do_sea(unsigned long far, unsigned long esr, struct pt_regs *regs)
 	const struct fault_info *inf;
 	unsigned long siaddr;
 
+	if (fixup_sea_exception(regs, esr))
+		return 0;
+
 	inf = esr_to_fault_info(esr);
 
 	if (user_mode(regs) && apei_claim_sea(regs) == 0) {

-- 
Git-155)

