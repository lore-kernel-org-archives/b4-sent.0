From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 27 Oct 2026 16:09:01 -0400
Subject: [PATCH] mm: annotate lockless accesses to vm_committed_as_batch
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-kcsan-mm-v1-1-66757485b917@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDAyNz3ezk4sQ83dxc3WQDQ3NLE1NTS1NLSyWg8oKi1LTMCrBR0bEQfnF
 pUlZqcglIv1JtLQCK5KvgbAAAAA==
X-Change-ID: 20261027-kcsan-mm-c01794559599
To: Mike Rapoport <rppt@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-mm@kvack.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793131741; l=2109;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=j7Mc9C4QlmCwhmnKNi4h7TqTqfjBLIBQjYqiZTNCEhg=;
 b=0Hqd2fa5iviDcBvKgRDs91aLAznIPOLYpILVxsb/Gu5CvLIwOieETU/yf+NKTPQfPHczGDeQK
 J9UjE21rqSfBHoTSVWFwm69tJ00PEmDUjslAk2LRNLpDoBJ9Upa1Mc5
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

vm_committed_as_batch is read without a lock, and it's only a hint for
how often the per-CPU counts get folded, so racing with an update is
harmless.  Annotate the accesses.

  [    0.953509] BUG: KCSAN: data-race in __vm_enough_memory / mm_compute_batch

  [    0.953645] write to 0xffffffff825165d8 of 4 bytes by task 1 on cpu 0:
  [    0.953692]  mm_compute_batch+0xc2/0x120
  [    0.953781]  mm_compute_batch_init+0x1c/0x20
  ...

  [    0.954325] read to 0xffffffff825165d8 of 4 bytes by task 41 on cpu 1:
  [    0.954373]  __vm_enough_memory+0x24/0x2b0
  [    0.954444]  shmem_inode_acct_blocks+0x1b3/0x230
  ...

  [    0.955288] value changed: 0x00000020 -> 0x00005003

Found with KCSAN while fuzzing under a deterministic hypervisor that's
currently under development.

Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 include/linux/mman.h | 3 ++-
 mm/mm_init.c         | 2 +-
 2 files changed, 3 insertions(+), 2 deletions(-)

diff --git a/include/linux/mman.h b/include/linux/mman.h
index 389521594c69..66e6c9c335b5 100644
--- a/include/linux/mman.h
+++ b/include/linux/mman.h
@@ -75,7 +75,8 @@ unsigned long vm_memory_committed(void);
 
 static inline void vm_acct_memory(long pages)
 {
-	percpu_counter_add_batch(&vm_committed_as, pages, vm_committed_as_batch);
+	percpu_counter_add_batch(&vm_committed_as, pages,
+				 data_race(vm_committed_as_batch));
 }
 
 static inline void vm_unacct_memory(long pages)
diff --git a/mm/mm_init.c b/mm/mm_init.c
index 41a27860d2f6..81f360db0787 100644
--- a/mm/mm_init.c
+++ b/mm/mm_init.c
@@ -211,7 +211,7 @@ void mm_compute_batch(int overcommit_policy)
 	else
 		memsized_batch = min_t(u64, ram_pages/nr/4, INT_MAX);
 
-	vm_committed_as_batch = max_t(s32, memsized_batch, batch);
+	WRITE_ONCE(vm_committed_as_batch, max_t(s32, memsized_batch, batch));
 }
 
 static int __meminit mm_compute_batch_notifier(struct notifier_block *self,

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-kcsan-mm-c01794559599

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

