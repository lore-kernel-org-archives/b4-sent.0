From: Sven Peter <sven@kernel.org>
Date: Wed, 08 Jul 2026 09:15:40 +0200
Subject: [PATCH RFC 4/6] arm64/efi: Honor EFI_MEMORY_ISA_MASK for
 Device-nGnRnE vs -nGnRE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260708-efi-psci-v1-4-9efb3abf0e4c@kernel.org>
References: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
In-Reply-To: <20260708-efi-psci-v1-0-9efb3abf0e4c@kernel.org>
To: Mark Rutland <mark.rutland@arm.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Ard Biesheuvel <ardb@kernel.org>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>, 
 Sudeep Holla <sudeep.holla@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-efi@vger.kernel.org, 
 asahi@lists.linux.dev, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1905; i=sven@kernel.org;
 h=from:subject:message-id; bh=/ejZ9kEPzd3EuCno7ps+9xBx6LGHpjeL3VowrnL2/78=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ5bvT20VobN/mkSjXybcUAyb9+Z88s/JF8WfOJrfK1Ge9
 T/5kZhWRykLgxgXg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiR68wMsw/Pqu0ZI/KjOyn
 DLbql2JYL5V908i9WRd1+mWnzWJHcUlGhqttB8R9OEyec165K7C9z9xZ4uftR93tR4XKbs1h4mX
 6wQ4A
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Apple Silicon, access to MMIO requires Device-nGnRnE while Device-nGnRE
results in SErrors. UEFI defines the EFI_MEMORY_ISA_MASK for cases like
that which just contains the MAIR attribute bits. We cannot support any
other Device- types without changing MAIR so just warn and fall back to
the previous default, Device-nGnRE, if we encounter anything else.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/kernel/efi.c | 24 +++++++++++++++++++++++-
 1 file changed, 23 insertions(+), 1 deletion(-)

diff --git a/arch/arm64/kernel/efi.c b/arch/arm64/kernel/efi.c
index e40885567f9e..50ba8e9112fc 100644
--- a/arch/arm64/kernel/efi.c
+++ b/arch/arm64/kernel/efi.c
@@ -7,6 +7,7 @@
  * Copyright (C) 2013, 2014 Linaro Ltd.
  */
 
+#include <linux/bitfield.h>
 #include <linux/efi.h>
 #include <linux/init.h>
 #include <linux/kmemleak.h>
@@ -16,6 +17,7 @@
 
 #include <asm/efi.h>
 #include <asm/stacktrace.h>
+#include <asm/sysreg.h>
 #include <asm/vmap_stack.h>
 
 
@@ -38,7 +40,27 @@ static __init ptval_t create_mapping_protection(efi_memory_desc_t *md)
 	u32 type = md->type;
 
 	if (type == EFI_MEMORY_MAPPED_IO) {
-		pgprot_t prot = __pgprot(PROT_DEVICE_nGnRE);
+		pgprot_t prot;
+
+		if (attr & EFI_MEMORY_ISA_VALID) {
+			u8 mair = FIELD_GET(EFI_MEMORY_ISA_MASK, attr);
+
+			switch (mair) {
+			case MAIR_ATTR_DEVICE_nGnRnE:
+				prot = __pgprot(PROT_DEVICE_nGnRnE);
+				break;
+			case MAIR_ATTR_DEVICE_nGnRE:
+				prot = __pgprot(PROT_DEVICE_nGnRE);
+				break;
+			default:
+				prot = __pgprot(PROT_DEVICE_nGnRE);
+				pr_warn("unsupported MAIR attribute %#x for EFI MMIO region at 0x%llx, using Device-nGnRE\n",
+					mair, md->phys_addr);
+				break;
+			}
+		} else {
+			prot = __pgprot(PROT_DEVICE_nGnRE);
+		}
 
 		if (arm64_is_protected_mmio(md->phys_addr,
 					    md->num_pages << EFI_PAGE_SHIFT))

-- 
2.55.0

