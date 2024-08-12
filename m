From: Miao Wang <shankerwangmiao@gmail.com>
Date: Mon, 12 Aug 2024 13:30:37 +0800
Subject: [PATCH] loongarch/dma: remove dma-direct.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240812-clean-dma-direct-v1-1-cbe19c2b73f5@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPyduWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDC0Mj3eSc1MQ83ZTcRN2UzKLU5BJdo9TUNOPkJINkSwtzJaC2gqLUtMw
 KsJHRsbW1AEdLvUBiAAAA
To: Huacai Chen <chenhuacai@kernel.org>, WANG Xuerui <kernel@xen0n.name>, 
 Jianmin Lv <lvjianmin@loongson.cn>, 
 "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, loongarch@lists.linux.dev, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1430;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=6+YGYrlc1s/mmh+MsuZbrcYqupZV/j2oMwcFLa6zqMk=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBmuZ3+mRWGBIf0jdhKntVHYO875ENqpkMxjjRQf
 ZhfS45W8TKJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZrmd/gAKCRCwMePKe/7Z
 bsM+D/94iBrxkvEVKmvMN7GD819XS7krOrwW37ut6PkOAnwAzn2nT/fMJtSr4I5RLe7AGifGG1a
 LTHeN2QCtj+qRfYMKDek0IjBItXliuBRfjEsPteJ9ofWAdL+l6atIxArD+9ikm3BESTekK8a7Kx
 Fajfaz+vuC6B5yMJj4DDKvRhqbPTUp82zPCRh39Bh2QCvpmi32RZvaMulZvlWcRhClrsQUCZGsA
 vfTo2P6LNFfWVrBE3jYszBlpJUwre9aFFA1+6XL0Q0KDTzFNXjFv71psjR2yPQhUmyWI4NfOBqr
 r0Ls6sYeSVlmAqlC0XNQq+mFrbl0hQysiUnXfjo/sty6oxnvM+cYBpKV1mAaj333HbYccGA5fey
 Ma7Cp5LVleTKq/YxX1pYdtDr+WlmCM0SDPRDzbnEBrCcNoiKKly3bzQRY8ZDsMlyopRGzkIn5CO
 qNJ2Q9rAMSmXtDtvF3sVMnfkSGG05RSYrtN+K0cDabLBrsW/5emxkhQ+lThlrvU4f42HboZHkkR
 lppLCZbZk5v8xoTDINzwOhrfRxHQcPXjucdxjG7Fq/AsMmfv/XS08CNPuGoqDWjU1zMOfatBcy1
 xoOmzGmjDhR1TazL0E2Sq7mJJSXEZVVp4Hg4MKFDTmk9dTzoX5oeFd6hsoBBkwmIofMDgOFnID0
 VscBwHeEtRpiREA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

dma-direct.h is introduced in commit d4b6f1562a3c ("LoongArch:
Add Non-Uniform Memory Access (NUMA) support"). In commit
c78c43fe7d42 ("LoongArch: Use acpi_arch_dma_setup() and remove
ARCH_HAS_PHYS_TO_DMA"), ARCH_HAS_PHYS_TO_DMA was deselected and
the coresponding phys_to_dma and dma_to_phys functions were
removed. However, the unused dma-direct.h was left behind,
which is removed by this patch.

Fixes: c78c43fe7d42 ("LoongArch: Use acpi_arch_dma_setup() and remove ARCH_HAS_PHYS_TO_DMA")
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
 arch/loongarch/include/asm/dma-direct.h | 11 -----------
 1 file changed, 11 deletions(-)

diff --git a/arch/loongarch/include/asm/dma-direct.h b/arch/loongarch/include/asm/dma-direct.h
deleted file mode 100644
index 75ccd808a2af..000000000000
--- a/arch/loongarch/include/asm/dma-direct.h
+++ /dev/null
@@ -1,11 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0 */
-/*
- * Copyright (C) 2020-2022 Loongson Technology Corporation Limited
- */
-#ifndef _LOONGARCH_DMA_DIRECT_H
-#define _LOONGARCH_DMA_DIRECT_H
-
-dma_addr_t phys_to_dma(struct device *dev, phys_addr_t paddr);
-phys_addr_t dma_to_phys(struct device *dev, dma_addr_t daddr);
-
-#endif /* _LOONGARCH_DMA_DIRECT_H */

---
base-commit: 7c626ce4bae1ac14f60076d00eafe71af30450ba
change-id: 20240812-clean-dma-direct-2eef3cb0c987

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

