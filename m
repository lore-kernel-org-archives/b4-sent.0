From: Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
Date: Tue, 13 Oct 2026 17:56:19 -0500
Subject: [PATCH] mm: nommu: set MMF_OOM_SKIP in exit_mmap()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-fix-nommu-exit-mmap-oom-skip-v1-1-cb957cdbfcc3@JohnDeere.com>
X-B4-Tracking: v=1; b=H4sIABK3zmoC/x3M0QqDMAxA0V+RPC/M6iiyXxl7aDVqGGlL4oYg/
 vu6PR643AOMlMng3hyg9GHjnCrcpYFxDWkh5KkaurbzrnU9zrxjyiJvpJ03FAkFcxa0FxeMA/k
 hzv0t+gnqoijV/r9/PKtjMMKoIY3rb5qVF05XCbaRwnl+Ab86sxaOAAAA
To: Andrew Morton <akpm@linux-foundation.org>
Cc: Michal Hocko <mhocko@suse.com>, "Liam R. Howlett" <liam@infradead.org>, 
 Lorenzo Stoakes <ljs@kernel.org>, linux-mm@kvack.org, 
 linux-kernel@vger.kernel.org, 
 Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791932178; l=1299;
 i=BouziguesAlexis@JohnDeere.com; s=20260527; h=from:subject:message-id;
 bh=hVmRWa/BeiGIHAxsid1KBCGZvcLmOYCtQjDsyT49U1Q=;
 b=j/+/Nm1eIrvkAXqIYV10l74NOMUNM9pNumM9DwYrXfv8vOfeIwzsbiovirVM036T7KgOoK0N7
 afOWB8waOp/Bdr5mYF9JJc3//T0l4KQzImC2s6ilcNMo4yoYzbz2reU
X-Developer-Key: i=BouziguesAlexis@JohnDeere.com; a=ed25519;
 pk=5KJ7ArL00x5flpPhi9zRLC2p88V1rZXDQ5SXhpRvTDk=
X-Endpoint-Received: by B4 Relay for BouziguesAlexis@JohnDeere.com/20260527 with auth_id=797
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 212925802454 ("mm: oom: let oom_reap_task and exit_mmap run
concurrently") moved setting MMF_OOM_SKIP from __mmput() into the MMU
exit_mmap(), so it is no longer set when a NOMMU mm is torn down.

As a result, a NOMMU OOM victim that has exited and freed its memory
keeps the OOM killer from selecting another victim until it is reaped.

Set MMF_OOM_SKIP in the NOMMU exit_mmap() once the VMAs are freed, as
the MMU version does.

Fixes: 212925802454 ("mm: oom: let oom_reap_task and exit_mmap run concurrently")
Assisted-by: LLM
Signed-off-by: Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>
---
Restore MMF_OOM_SKIP on NOMMU mm teardown, which was lost when it moved
into the MMU-only exit_mmap().
---
 mm/nommu.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/mm/nommu.c b/mm/nommu.c
index 498e01ee40b0..913b2a1b5b3b 100644
--- a/mm/nommu.c
+++ b/mm/nommu.c
@@ -1555,6 +1555,7 @@ void exit_mmap(struct mm_struct *mm)
 		delete_vma(mm, vma);
 		cond_resched();
 	}
+	mm_flags_set(MMF_OOM_SKIP, mm);
 	__mt_destroy(&mm->mm_mt);
 	mmap_write_unlock(mm);
 }

---
base-commit: 24a19b953e2a3d0ea5a8c4951a0ab8f32720c907
change-id: 20261013-fix-nommu-exit-mmap-oom-skip-b8e68bf34b6d

Best regards,
-- 
Alexis Bouzigues <BouziguesAlexis@JohnDeere.com>

