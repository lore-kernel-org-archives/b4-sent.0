From: Hunter Laux <hunterlaux@gmail.com>
Date: Tue, 10 Nov 2026 09:53:47 -0700
Subject: [PATCH] MIPS: kexec: Fix kexec on 32-bit non-EVA systems with
 HIGHMEM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261110-mips-kexec-highmem-v1-1-a42c73f840f1@gmail.com>
X-B4-Tracking: v=1; b=H4sIABpM82oC/x3MQQqAIBBA0avErBtQqYSuEi1MRx3CCoUIwrsnL
 d/i/xcKZaYCc/dCppsLn0eD7Duw0RyBkF0zKKEmKaXAxFfBnR6yGDnERAkHO+jNuVEb4aGFVyb
 Pzz9d1lo/bWp78WQAAAA=
To: Thomas Bogendoerfer <tsbogend@alpha.franken.de>
Cc: linux-mips@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hunter Laux <hunterlaux@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794329629; l=2359;
 i=hunterlaux@gmail.com; s=20261109; h=from:subject:message-id;
 bh=8a0ywquQKIDmQQiIIGS2OKCO8sdfm5iRqpZglhcUqIY=;
 b=tE2Kb3U5AuklJRYLNk9v2s7W2tML2nBVds4XA7Xi1+S+zVsABdw+a38/d/vn+kF/KRJTcOHFE
 79NhsMf1VYLDZNKRAoseGyUmmtTETVKNyVjrDECZ70j7fdp0bqnL8b4
X-Developer-Key: i=hunterlaux@gmail.com; a=ed25519;
 pk=Z5VTsE4CAwditt0CNeG+rpPk7xDUVh+oHWDZlNNm8FI=
X-Endpoint-Received: by B4 Relay for hunterlaux@gmail.com/20261109 with auth_id=1476
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a6da4d6fdf8b ("MIPS: kexec: Relax memory restriction") lifted
the 512 MiB limit on the pages kexec copies the new image from and to.
relocate_kernel.S reaches those pages through phys_to_virt(), which
only covers lowmem. On a 32-bit kernel with HIGHMEM, the source pages
are allocated with GFP_HIGHUSER, and one in highmem becomes an address
that isn't that page: physical 0x30060000 becomes 0xb0060000, the
uncached alias of 0x10060000. The new image is copied from there and
the jump to it fails with a Reserved Instruction exception.

Limit the source and destination pages to HIGHMEM_START - 1: the old
512 MiB on most 32-bit platforms, and no limit on 64-bit kernels, where
HIGHMEM_START is beyond any memory.

Platforms with more than 512 MiB of lowmem, such as 32-bit EVA
systems, raise HIGHMEM_START and keep the larger limit.

kimage_alloc_page() keeps the highmem pages it rejects until the image
is unloaded or executed, so loading an image on a HIGHMEM system now
holds most of the free highmem in the meantime. kexec -p is not
affected.

Fixes: a6da4d6fdf8b ("MIPS: kexec: Relax memory restriction")
Assisted-by: Claude:claude-opus-5-5
Signed-off-by: Hunter Laux <hunterlaux@gmail.com>
---
 arch/mips/include/asm/kexec.h | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/arch/mips/include/asm/kexec.h b/arch/mips/include/asm/kexec.h
index 69e579e41e..5f57bbc8c3 100644
--- a/arch/mips/include/asm/kexec.h
+++ b/arch/mips/include/asm/kexec.h
@@ -7,12 +7,13 @@
 #ifndef _MIPS_KEXEC
 # define _MIPS_KEXEC
 
+#include <asm/page.h>
 #include <asm/stacktrace.h>
 
 /* Maximum physical address we can use pages from */
-#define KEXEC_SOURCE_MEMORY_LIMIT (-1UL)
-/* Maximum address we can reach in physical address mode */
-#define KEXEC_DESTINATION_MEMORY_LIMIT (-1UL)
+#define KEXEC_SOURCE_MEMORY_LIMIT (HIGHMEM_START - 1)
+/* Maximum physical address we can copy the image to */
+#define KEXEC_DESTINATION_MEMORY_LIMIT (HIGHMEM_START - 1)
  /* Maximum address we can use for the control code buffer */
 #define KEXEC_CONTROL_MEMORY_LIMIT (-1UL)
 /* Reserve 3*4096 bytes for board-specific info */

---
base-commit: b3dfbde62cf1981c4638939c159dfd087b7a72e9
change-id: 20261110-mips-kexec-highmem-4c47bdd57a0f

Best regards,
-- 
Hunter Laux <hunterlaux@gmail.com>

