From: Janne Grunau <j@jannau.net>
Date: Thu, 30 Nov 2023 13:42:22 +0100
Subject: [PATCH] arm: apple: t602x: Add missing MMIO regions to memmap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231130-apple_t602x_extend_memmap-v1-1-cd96b251d2dc@jannau.net>
X-B4-Tracking: v=1; b=H4sIAC2DaGUC/x3MQQrDIBBG4auEWVfQCQ0hVylFZPK3GYhWNBQh5
 O6VLr/FeydVFEWlZTip4KtVP6nD3QaSLaQ3jK7dxJZH50ZrQs47/DFZbh7tQFp9RIwhG5lZ7sw
 SZrHU+1zw0vZ/P57X9QPVnBPOawAAAA==
To: Mark Kettenis <kettenis@openbsd.org>, Tom Rini <trini@konsulko.com>
Cc: u-boot@lists.denx.de, asahi@lists.linux.dev
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2856; i=j@jannau.net;
 h=from:subject:message-id; bh=BdZFDD0ocvWdf4L8IT2OEBDK4E8bBAFq03bgl1BRcDE=;
 b=owGbwMvMwCG2UNrmdq9+ahrjabUkhtSMZqv9kW/cMvOvs661u+Uae/kI75ZJKzuv7MufV33HI
 XR52K7pHaUsDGIcDLJiiixJ2i87GFbXKMbUPgiDmcPKBDKEgYtTACbyIo7hv+dcjqijiu7RUqb7
 r/yabGgRlFSy+e6d73mH5p87c1Hbo5/hn4Kx5qM1hz5afjL1n/BsW8NWOdeItZ8fXD0i83FrWce
 jFEYA
X-Developer-Key: i=j@jannau.net; a=openpgp;
 fpr=8B336A6BE4E5695E89B8532B81E806F586338419
X-Endpoint-Received: by B4 Relay for j@jannau.net/default with auth_id=62
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The memory maps for Apple's M2 Pro/Max/Ultra left MMIO space out which
was not used by any driver at the time. The display out exposed as
simple-framebuffer use a power-domain controlled by a device in an
unmapped region.
Add a map covering this region as well as another MMIO region in the
range 0x4'0000'0000 - 0x5'0000'0000. The added regions cover all MMIO
annotated in Apple's device tree in this range.

Signed-off-by: Janne Grunau <j@jannau.net>
---
 arch/arm/mach-apple/board.c | 48 +++++++++++++++++++++++++++++++++++++++++++++
 1 file changed, 48 insertions(+)

diff --git a/arch/arm/mach-apple/board.c b/arch/arm/mach-apple/board.c
index 47393babbc..e05ec431bc 100644
--- a/arch/arm/mach-apple/board.c
+++ b/arch/arm/mach-apple/board.c
@@ -370,6 +370,22 @@ static struct mm_region t6020_mem_map[] = {
 		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
 			 PTE_BLOCK_NON_SHARE |
 			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* I/O */
+		.virt = 0x400000000,
+		.phys = 0x400000000,
+		.size = SZ_512M,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			PTE_BLOCK_NON_SHARE |
+			PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* I/O */
+		.virt = 0x480000000,
+		.phys = 0x480000000,
+		.size = SZ_1G,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			PTE_BLOCK_NON_SHARE |
+			PTE_BLOCK_PXN | PTE_BLOCK_UXN
 	}, {
 		/* I/O */
 		.virt = 0x580000000,
@@ -471,6 +487,22 @@ static struct mm_region t6022_mem_map[] = {
 		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
 			 PTE_BLOCK_NON_SHARE |
 			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* I/O */
+		.virt = 0x400000000,
+		.phys = 0x400000000,
+		.size = SZ_512M,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			PTE_BLOCK_NON_SHARE |
+			PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* I/O */
+		.virt = 0x480000000,
+		.phys = 0x480000000,
+		.size = SZ_1G,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			PTE_BLOCK_NON_SHARE |
+			PTE_BLOCK_PXN | PTE_BLOCK_UXN
 	}, {
 		/* I/O */
 		.virt = 0x580000000,
@@ -551,6 +583,22 @@ static struct mm_region t6022_mem_map[] = {
 		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
 			 PTE_BLOCK_NON_SHARE |
 			 PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* I/O */
+		.virt = 0x2400000000,
+		.phys = 0x2400000000,
+		.size = SZ_512M,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			PTE_BLOCK_NON_SHARE |
+			PTE_BLOCK_PXN | PTE_BLOCK_UXN
+	}, {
+		/* I/O */
+		.virt = 0x2480000000,
+		.phys = 0x2480000000,
+		.size = SZ_1G,
+		.attrs = PTE_BLOCK_MEMTYPE(MT_DEVICE_NGNRNE) |
+			PTE_BLOCK_NON_SHARE |
+			PTE_BLOCK_PXN | PTE_BLOCK_UXN
 	}, {
 		/* I/O */
 		.virt = 0x2580000000,

---
base-commit: 43f2873fa98b1da6eb56d756315c7bd7db63db27
change-id: 20231130-apple_t602x_extend_memmap-c82c522ca8c0

Best regards,
-- 
Janne Grunau <j@jannau.net>

