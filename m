From: Manas <manas18244@iiitd.ac.in>
Date: Mon, 21 Oct 2024 22:18:57 +0530
Subject: [PATCH] Revert "bcachefs: Add asserts to
 bch2_dev_btree_bitmap_marked_sectors()"
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241021-revert-assert-bch2-v1-1-e869c7c55bb6@iiitd.ac.in>
X-B4-Tracking: v=1; b=H4sIAPmFFmcC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxNDAyNDXaCi1KIS3cTiYhCVlJxhpGtkamJukpZqYWCZYqgE1FhQlJqWWQE
 2NDq2thYAFnuBOGQAAAA=
X-Change-ID: 20241021-revert-assert-bch2-25474fe809d1
To: Kent Overstreet <kent.overstreet@linux.dev>
Cc: linux-bcachefs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Anup Sharma <anupnewsmail@gmail.com>, 
 Shuah Khan <skhan@linuxfoundation.org>, Manas <manas18244@iiitd.ac.in>, 
 syzbot+e8eff054face85d7ea41@syzkaller.appspotmail.com
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729529344; l=1877;
 i=manas18244@iiitd.ac.in; s=20240813; h=from:subject:message-id;
 bh=M5hbMLylF0b+ZchbJH4bBirAx8QVk4kpDgu8JqXEiG0=;
 b=WgevtVQ8IzkqKxDmL4PPt4x+pwzKgX51dRXKIkpi/bHg+qtl1U1+wYlMsvhRz3aI+SKqx7uQJ
 /moCqOYxegOAir9iBXGhNInRIgLvsv2CRck4KxE2nrWm2swoQTEIXd3
X-Developer-Key: i=manas18244@iiitd.ac.in; a=ed25519;
 pk=pXNEDKd3qTkQe9vsJtBGT9hrfOR7Dph1rfX5ig2AAoM=
X-Endpoint-Received: by B4 Relay for manas18244@iiitd.ac.in/20240813 with auth_id=196
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This reverts commit 60f2b1bcf519416dbffee219132aa949d0c39d0e.

This syzbot bug[1] is triggered due to the BUG_ON assertions added in
__bch2_dev_btree_bitmap_mark. During runtime, m->btree_bitmap_shift is
63 '?'. This triggers both the assertions.

Reverting the commit does not reproduce the said bug.

[1] https://syzkaller.appspot.com/bug?extid=e8eff054face85d7ea41

Signed-off-by: Manas <manas18244@iiitd.ac.in>
Reported-by: syzbot+e8eff054face85d7ea41@syzkaller.appspotmail.com
Closes: https://syzkaller.appspot.com/bug?extid=e8eff054face85d7ea41
---
This syzbot bug[1] is triggered due to the BUG_ON assertions added in
__bch2_dev_btree_bitmap_mark. During runtime, m->btree_bitmap_shift is
63 '?'. This triggers both the assertions.

I am unfamiliar with the codebase, and there wasn't a lore discussion
about the assertions in the commit, so I am unsure about the relevance
of these assertions.

Reverting the commit does not reproduce the said bug.

[1] https://syzkaller.appspot.com/bug?extid=e8eff054face85d7ea41
---
 fs/bcachefs/sb-members.c | 3 ---
 1 file changed, 3 deletions(-)

diff --git a/fs/bcachefs/sb-members.c b/fs/bcachefs/sb-members.c
index fb08dd680dacf82bca414f424024e4a00bf432de..9790fd47338c46d2af30547e1f41a1e578b71aa4 100644
--- a/fs/bcachefs/sb-members.c
+++ b/fs/bcachefs/sb-members.c
@@ -450,9 +450,6 @@ static void __bch2_dev_btree_bitmap_mark(struct bch_sb_field_members_v2 *mi, uns
 		m->btree_bitmap_shift += resize;
 	}
 
-	BUG_ON(m->btree_bitmap_shift > 57);
-	BUG_ON(end > 64ULL << m->btree_bitmap_shift);
-
 	for (unsigned bit = start >> m->btree_bitmap_shift;
 	     (u64) bit << m->btree_bitmap_shift < end;
 	     bit++)

---
base-commit: 42f7652d3eb527d03665b09edac47f85fb600924
change-id: 20241021-revert-assert-bch2-25474fe809d1

Best regards,
-- 
Manas <manas18244@iiitd.ac.in>

