From: Dave Vasilevsky <dave@vasilevsky.ca>
Date: Mon, 27 Oct 2025 19:21:47 -0400
Subject: [PATCH] powerpc: Fix mprotect on book3s32
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251027-vasi-mprotect-g3-v1-1-3c5187085f9a@vasilevsky.ca>
X-B4-Tracking: v=1; b=H4sIAIr+/2gC/x3MQQqAIBBA0avErBtQS5SuEi0ix5pFKhoRhHdPW
 r7F/y8UykwFpu6FTDcXjqFB9h1sxxp2QnbNoITSUiiD91oYz5TjRduF+4Deeq2MdaMcBbQsZfL
 8/Mt5qfUDcHtzDGIAAAA=
X-Change-ID: 20251027-vasi-mprotect-g3-f8f5278d4140
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 Christophe Leroy <christophe.leroy@csgroup.eu>, 
 Nadav Amit <nadav.amit@gmail.com>, 
 "Peter Zijlstra (Intel)" <peterz@infradead.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Dave Vasilevsky <dave@vasilevsky.ca>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761607334; l=2972;
 i=dave@vasilevsky.ca; s=20251027; h=from:subject:message-id;
 bh=E1aBGzZxrKFyEjSh5tyf0kwyoQ+SazFw/xbQmkHQC8c=;
 b=stXn+ddNorVpT4m4xv4DpE0jTKLzbB53xuvhLM3AsQqN7nWd+GkbidV1wVWZ/ynrPTQgsSvxj
 RF8akzSsGFIAuOfxrGVn1gCyHKBiUqsfRdMLRLPFG2DkjhzYuR0HhW/
X-Developer-Key: i=dave@vasilevsky.ca; a=ed25519;
 pk=Jsd1btZeqqg6x6y73Dx0YrleQb3A3pCBnUeE0qmoKq4=
X-Endpoint-Received: by B4 Relay for dave@vasilevsky.ca/20251027 with auth_id=556
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On 32-bit book3s with hash-MMUs, tlb_flush() was a no-op. This was
unnoticed because all uses until recently were for unmaps, and thus
handled by __tlb_remove_tlb_entry().

After commit 4a18419f71cd ("mm/mprotect: use mmu_gather") in kernel 5.19,
tlb_gather_mmu() started being used for mprotect as well. This caused
mprotect to simply not work on these machines:

  int *ptr = mmap(NULL, 4096, PROT_READ|PROT_WRITE,
                  MAP_PRIVATE|MAP_ANONYMOUS, -1, 0);
  *ptr = 1; // force HPTE to be created
  mprotect(ptr, 4096, PROT_READ);
  *ptr = 2; // should segfault, but succeeds

Fixed by making tlb_flush() actually flush TLB pages. This finally
agrees with the behaviour of boot3s64's tlb_flush().

Fixes: 4a18419f71cd ("mm/mprotect: use mmu_gather")
Signed-off-by: Dave Vasilevsky <dave@vasilevsky.ca>
---
 arch/powerpc/include/asm/book3s/32/tlbflush.h | 8 ++++++--
 arch/powerpc/mm/book3s32/tlb.c                | 6 ++++++
 2 files changed, 12 insertions(+), 2 deletions(-)

diff --git a/arch/powerpc/include/asm/book3s/32/tlbflush.h b/arch/powerpc/include/asm/book3s/32/tlbflush.h
index e43534da5207aa3b0cb3c07b78e29b833c141f3f..b8c587ad2ea954f179246a57d6e86e45e91dcfdc 100644
--- a/arch/powerpc/include/asm/book3s/32/tlbflush.h
+++ b/arch/powerpc/include/asm/book3s/32/tlbflush.h
@@ -11,6 +11,7 @@
 void hash__flush_tlb_mm(struct mm_struct *mm);
 void hash__flush_tlb_page(struct vm_area_struct *vma, unsigned long vmaddr);
 void hash__flush_range(struct mm_struct *mm, unsigned long start, unsigned long end);
+void hash__flush_gather(struct mmu_gather *tlb);
 
 #ifdef CONFIG_SMP
 void _tlbie(unsigned long address);
@@ -28,9 +29,12 @@ void _tlbia(void);
  */
 static inline void tlb_flush(struct mmu_gather *tlb)
 {
-	/* 603 needs to flush the whole TLB here since it doesn't use a hash table. */
-	if (!mmu_has_feature(MMU_FTR_HPTE_TABLE))
+	if (mmu_has_feature(MMU_FTR_HPTE_TABLE)) {
+		hash__flush_gather(tlb);
+	} else {
+		/* 603 needs to flush the whole TLB here since it doesn't use a hash table. */
 		_tlbia();
+	}
 }
 
 static inline void flush_range(struct mm_struct *mm, unsigned long start, unsigned long end)
diff --git a/arch/powerpc/mm/book3s32/tlb.c b/arch/powerpc/mm/book3s32/tlb.c
index 9ad6b56bfec96e989b96f027d075ad5812500854..3da95ecfbbb296303082e378425e92a5fbdbfac8 100644
--- a/arch/powerpc/mm/book3s32/tlb.c
+++ b/arch/powerpc/mm/book3s32/tlb.c
@@ -105,3 +105,9 @@ void hash__flush_tlb_page(struct vm_area_struct *vma, unsigned long vmaddr)
 		flush_hash_pages(mm->context.id, vmaddr, pmd_val(*pmd), 1);
 }
 EXPORT_SYMBOL(hash__flush_tlb_page);
+
+void hash__flush_gather(struct mmu_gather *tlb)
+{
+	hash__flush_range(tlb->mm, tlb->start, tlb->end);
+}
+EXPORT_SYMBOL(hash__flush_gather);

---
base-commit: dcb6fa37fd7bc9c3d2b066329b0d27dedf8becaa
change-id: 20251027-vasi-mprotect-g3-f8f5278d4140

Best regards,
-- 
Dave Vasilevsky <dave@vasilevsky.ca>

