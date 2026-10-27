From: Mani Tofigh <mt4022@columbia.edu>
Date: Tue, 27 Oct 2026 16:09:23 -0400
Subject: [PATCH] exit: use READ_ONCE() to read mm->owner
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261027-kcsan-exit-v1-1-7c0429a29bc0@columbia.edu>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqAIBBA4avErBNU6Pcq0aJ0qimwcCyC6O5ZL
 b/FexcwekKGOrnA40FMq4tQaQJm6tyIgmw0aKlzJXUhFsOdE3hSEEpW1mCuM1sqiMHmcaDzmzX
 tb977GU14D3DfD5lpoW9uAAAA
X-Change-ID: 20261027-kcsan-exit-109dce625d81
To: Oleg Nesterov <oleg@redhat.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Christian Brauner <brauner@kernel.org>
Cc: linux-mm@kvack.org, linux-kernel@vger.kernel.org, tz2294@columbia.edu, 
 Mani Tofigh <mt4022@columbia.edu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793131763; l=1574;
 i=mt4022@columbia.edu; s=20261026; h=from:subject:message-id;
 bh=WXjCMdCN2l86r1jkTnC4XOf4kZ6T9fA2oOWN9xZ8maQ=;
 b=P4fzFN8wMHtZOrSvTz2cGZqT83oLhWqh1Yl+Q6idpSUy4YBkJ/VD293cGAp/MVmQ0NcTSTKL6
 UTAzDy6KdpKAIEtlMq8vulmMt2Se0lha0gFkV8W1YvL068x2hwvXryx
X-Developer-Key: i=mt4022@columbia.edu; a=ed25519;
 pk=gljCMQDuxyKPmd5y37CRpEJGSPXDV1MyAnHBhCgXl0I=
X-Endpoint-Received: by B4 Relay for mt4022@columbia.edu/20261026 with auth_id=1322
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

mm->owner is written with WRITE_ONCE() when ownership moves to another
task, but mm_update_next_owner() reads it with a plain load.  The race
is expected, so read it with READ_ONCE() to match the writer.

  [   14.915975] BUG: KCSAN: data-race in mm_update_next_owner / try_to_set_owner

  [   14.916154] write (marked) to 0xff11000004471b80 of 8 bytes by task 71 on cpu 0:
  [   14.916204]  try_to_set_owner+0x100/0x140
  [   14.916302]  mm_update_next_owner+0x177/0x300
  ...

  [   14.917246] read to 0xff11000004471b80 of 8 bytes by task 75 on cpu 1:
  [   14.917293]  mm_update_next_owner+0x2a/0x300
  [   14.917396]  do_exit+0x575/0x18b0
  ...

  [   14.923906] value changed: 0xff1100002ec04180 -> 0xff1100002ed3a0c0

Found with KCSAN while fuzzing under a deterministic hypervisor that's
currently under development.

Signed-off-by: Mani Tofigh <mt4022@columbia.edu>
---
 kernel/exit.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/kernel/exit.c b/kernel/exit.c
index d5e7bc2af804..cc78596db74d 100644
--- a/kernel/exit.c
+++ b/kernel/exit.c
@@ -494,7 +494,7 @@ void mm_update_next_owner(struct mm_struct *mm)
 	 * If the exiting or execing task is not the owner, it's
 	 * someone else's problem.
 	 */
-	if (mm->owner != p)
+	if (READ_ONCE(mm->owner) != p)
 		return;
 	/*
 	 * The current owner is exiting/execing and there are no other

---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20261027-kcsan-exit-109dce625d81

Best regards,
--  
Mani Tofigh <mt4022@columbia.edu>

