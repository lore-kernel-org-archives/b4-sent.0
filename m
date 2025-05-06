From: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
Date: Tue, 06 May 2025 15:44:33 +0200
Subject: [PATCH v2 2/2] mm: madvise: no-op for MADV_NOHUGEPAGE if THP is
 disabled
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250506-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v2-2-f11f0c794872@kuka.com>
References: <20250506-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v2-0-f11f0c794872@kuka.com>
In-Reply-To: <20250506-map-map_stack-to-vm_nohugepage-only-if-thp-is-enabled-v2-0-f11f0c794872@kuka.com>
To: lorenzo.stoakes@oracle.com
Cc: Liam.Howlett@oracle.com, akpm@linux-foundation.org, 
 yang@os.amperecomputing.com, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>, 
 Matthew Wilcox <willy@infradead.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1746539072; l=1361;
 i=Ignacio.MorenoGonzalez@kuka.com; s=20220915; h=from:subject:message-id;
 bh=mZUe80SjjB0V+4EVN/Y+dsF/fiezXfRRXC2NP5J4EHM=;
 b=jxT00NHjKAHXYvlci1kq/Iwg3Nujh6KnKh0VA1tFn9F+W21DkyxkRefWe7O0qebY6rwyQ0h6L
 FbxTdmx1iQBC9pqJTsMVAUZvGQdsPZvrTI/h6+7B/GrzTFUVZwsbaWg
X-Developer-Key: i=Ignacio.MorenoGonzalez@kuka.com; a=ed25519;
 pk=j7nClQnc5Q1IDuT4eS/rYkcLHXzxszu2jziMcJaFdBQ=
X-Endpoint-Received: by B4 Relay for Ignacio.MorenoGonzalez@kuka.com/20220915 with auth_id=391
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

VM_NOHUGEPAGE is a no-op in a kernel without THP. So it makes no sense
to return an error when calling madvise() with MADV_NOHUGEPAGE.

Suggested-by: Matthew Wilcox <willy@infradead.org>
Reviewed-by: Lorenzo Stoakes <lorenzo.stoakes@oracle.com>
Reviewed-by: Yang Shi <yang@os.amperecomputing.com>
Signed-off-by: Ignacio Moreno Gonzalez <Ignacio.MorenoGonzalez@kuka.com>
---
 include/linux/huge_mm.h | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/include/linux/huge_mm.h b/include/linux/huge_mm.h
index e893d546a49f464f7586db639fe216231f03651a..cdb991f9be918182f94003394cf793654a080224 100644
--- a/include/linux/huge_mm.h
+++ b/include/linux/huge_mm.h
@@ -7,6 +7,10 @@
 #include <linux/fs.h> /* only for vma_is_dax() */
 #include <linux/kobject.h>
 
+#ifndef CONFIG_TRANSPARENT_HUGEPAGE
+#include <uapi/asm-generic/mman-common.h>
+#endif
+
 vm_fault_t do_huge_pmd_anonymous_page(struct vm_fault *vmf);
 int copy_huge_pmd(struct mm_struct *dst_mm, struct mm_struct *src_mm,
 		  pmd_t *dst_pmd, pmd_t *src_pmd, unsigned long addr,
@@ -598,6 +602,8 @@ static inline bool unmap_huge_pmd_locked(struct vm_area_struct *vma,
 static inline int hugepage_madvise(struct vm_area_struct *vma,
 				   unsigned long *vm_flags, int advice)
 {
+	if (advice == MADV_NOHUGEPAGE)
+		return 0;
 	return -EINVAL;
 }
 

-- 
2.39.5

