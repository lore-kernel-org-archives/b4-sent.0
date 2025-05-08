From: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
Date: Thu, 08 May 2025 12:20:27 +0200
Subject: [PATCH] mm: madvise: make MADV_NOHUGEPAGE a no-op if !THP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250508-madvise-nohugepage-noop-without-thp-v1-1-e7ceffb197f3@kuka.com>
X-B4-Tracking: v=1; b=H4sIAGqFHGgC/x2NwQqFIBBFfyVm3YAZUb1febSwnHQWqai9F0T/n
 rU7Bw73npAoMiX4VCdE+nFi74o0dQWLVc4Qsi4OUshOdGLATelSETpvd0NBmQd9wD9n6/eM2QY
 k0ctmHvtWDxLKUoi08vG+fKfrugGPv6WIdQAAAA==
X-Change-ID: 20250508-madvise-nohugepage-noop-without-thp-e0721b973d82
To: Andrew Morton <akpm@linux-foundation.org>, 
 Lorenzo Stoakes <lorenzo.stoakes@oracle.com>, 
 "Liam R. Howlett" <Liam.Howlett@oracle.com>
Cc: yang@os.amperecomputing.com, willy@infradead.org, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746699627; l=1782;
 i=Ignacio.MorenoGonzalez@kuka.com; s=20220915; h=from:subject:message-id;
 bh=WkzJ0m077QxoI+DJujIZqVZ01oTbN6BGwiqxdFPO/Rw=;
 b=HOKlWk8Cdb9oLxFnVCfZg9m12ukVQDxIoiovVUj19FPzBgRmFxHHXyOSU5Q53OjwdQhCgF4zV
 awvIV6P9FYcCxg4MhvNDpGrgPL5lXCBVucnaF5yKAtHrhHwQSEiMk/F
X-Developer-Key: i=Ignacio.MorenoGonzalez@kuka.com; a=ed25519;
 pk=j7nClQnc5Q1IDuT4eS/rYkcLHXzxszu2jziMcJaFdBQ=
X-Endpoint-Received: by B4 Relay for Ignacio.MorenoGonzalez@kuka.com/20220915 with auth_id=391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

VM_NOHUGEPAGE is a no-op if CONFIG_TRANSPARENT_HUGEPAGE is disabled. So
it makes no sense to return an error when calling madvise() with
MADV_NOHUGEPAGE in that case.

Suggested-by: Matthew Wilcox <willy@infradead.org>
Signed-off-by: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
---
https://lore.kernel.org/linux-mm/20250502-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v1-1-113cc634cd51@kuka.com

Here it is presented as a separate thread to avoid mixing stable and
non-stable patches.

This change makes calling madvise(addr, size, MADV_NOHUGEPAGE) on !THP
kernels to return 0 instead of -EINVAL.
---
 include/linux/huge_mm.h | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/include/linux/huge_mm.h b/include/linux/huge_mm.h
index e893d546a49f464f7586db639fe216231f03651a..5fca742dc5ba784ffccea055b07247707d16cc67 100644
--- a/include/linux/huge_mm.h
+++ b/include/linux/huge_mm.h
@@ -509,6 +509,8 @@ bool unmap_huge_pmd_locked(struct vm_area_struct *vma, unsigned long addr,
 
 #else /* CONFIG_TRANSPARENT_HUGEPAGE */
 
+#include <uapi/asm/mman.h>
+
 static inline bool folio_test_pmd_mappable(struct folio *folio)
 {
 	return false;
@@ -598,6 +600,9 @@ static inline bool unmap_huge_pmd_locked(struct vm_area_struct *vma,
 static inline int hugepage_madvise(struct vm_area_struct *vma,
 				   unsigned long *vm_flags, int advice)
 {
+	/* On a !THP kernel, MADV_NOHUGEPAGE is a no-op, but MADV_NOHUGEPAGE is not supported */
+	if (advice == MADV_NOHUGEPAGE)
+		return 0;
 	return -EINVAL;
 }
 

---
base-commit: fc96b232f8e7c0a6c282f47726b2ff6a5fb341d2
change-id: 20250508-madvise-nohugepage-noop-without-thp-e0721b973d82

Best regards,
-- 
Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>

