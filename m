From: Joas Antonio dos Santos <joasantonio108@gmail.com>
Date: Sun, 08 Nov 2026 18:05:33 +0000
Subject: [PATCH] ntfs3: fix bitmap corruption in attr_allocate_clusters()
 error path
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261108-ntfs3-alloc-undo-fix-v1-1-280fc5d06af6@gmail.com>
X-B4-Tracking: v=1; b=H4sIAOy58GoC/x2MWwqAIBAArxL73YL2EOkq0YfWWguhoRVBePekz
 xmYeSFRZEowVC9Eujlx8AVkXcG8Gb8S8lIYGtEoKYVGf7rUotn3MOPll4COHyTVWW2F02R6KOk
 Rqeh/O045f2yVh/NmAAAA
To: joasantonio108@gmail.com, 
 Konstantin Komarov <almaz.alexandrovich@paragon-software.com>
Cc: linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794161132; l=1878;
 i=joasantonio108@gmail.com; s=20261031; h=from:subject:message-id;
 bh=2dxHVeInvQx1GDisuSMbfr3SxQuAoN46Qasuyi4MfXo=;
 b=cJGwzp38Pd/KvngKhHz5vO1+8c9AsKo8kNE8OgpzWQupgBpZmepvkR+NQ5gFotXwsa+TB8tNG
 mX6k24MOFjKDadEbaVUEKDbP1XlADk8SEybDH05AdmK5hyukwQ5Y+r0
X-Developer-Key: i=joasantonio108@gmail.com; a=ed25519;
 pk=ZxAznJT/FcPPdzLrDDFJQm4LLjjHVGBBqDSG3TXS23w=
X-Endpoint-Received: by B4 Relay for joasantonio108@gmail.com/20261031 with auth_id=1371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The undo_alloc error path in attr_allocate_clusters() calls
mark_as_free_ex() with len (remaining clusters to allocate) instead
of flen (clusters actually allocated in the last iteration).

After the first loop iteration, len is decremented by flen, so on
subsequent iterations len represents only the remaining request size.
When run_add_entry() or run_remove_range() fails, the undo frees len
clusters starting at lcn, but only flen clusters at that position
were actually allocated. The excess clusters may belong to other files,
corrupting the allocation bitmap and causing silent data loss.

For example: a 100-cluster request where the first iteration allocates
60 (len becomes 40), and the second allocates 20 at a new lcn. If
run_add_entry() fails, undo frees 40 clusters at lcn when only 20 were
allocated there, marking 20 clusters of other files as free.

Fix by passing flen instead of len to mark_as_free_ex().

Found by LLM-assisted manual code review.

Fixes: be71b5cba2e6 ("fs/ntfs3: Add attrib operations")
Signed-off-by: Joas Antonio dos Santos <joasantonio108@gmail.com>
---
 fs/ntfs3/attrib.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/fs/ntfs3/attrib.c b/fs/ntfs3/attrib.c
index 805acc3ed..2a75ee162 100644
--- a/fs/ntfs3/attrib.c
+++ b/fs/ntfs3/attrib.c
@@ -207,7 +207,7 @@ int attr_allocate_clusters(struct ntfs_sb_info *sbi, struct runs_tree *run,
 		if (!run_add_entry(run, vcn, lcn, flen, opt & ALLOCATE_MFT)) {
 undo_alloc:
 			/* Undo last 'ntfs_look_for_free_space' */
-			mark_as_free_ex(sbi, lcn, len, false);
+			mark_as_free_ex(sbi, lcn, flen, false);
 			err = -ENOMEM;
 			goto out;
 		}

---
base-commit: 05441d697f7f9a927264f4058cbbc6a03dfcac9d
change-id: 20261108-ntfs3-alloc-undo-fix-e64b8b0f8ea5

Best regards,
-- 
Joas Antonio dos Santos <joasantonio108@gmail.com>

