From: FAN YE <fy15309206903@gmail.com>
Date: Sun, 23 Aug 2026 11:50:09 +0000
Subject: [PATCH RFC] btrfs: drop the ineffective barrier in
 should_cow_block()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260823-btrfs-drop-ineffective-barrier-v1-1-48854e8b847a@gmail.com>
X-B4-Tracking: v=1; b=H4sIAHDeimoC/yWNQQrCQAxFr1KyNjAzpSJuBQ/gVlw004zGxbQkt
 Qildzfq8j34769grMIGx2YF5UVMxuoQdw3kR1/vjDI4QwppHw6pRZq1GA46TiiVS+E8y8JIvXp
 HMbcxJu46CoHAI5Nykffv4AqX8wluf2kvevr0m4Zt+wA5UDYDhwAAAA==
X-Change-ID: 20260823-btrfs-drop-ineffective-barrier-c3112e55b00b
To: David Sterba <dsterba@suse.com>, Chris Mason <clm@fb.com>
Cc: linux-kernel@vger.kernel.org, linux-btrfs@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787485808; l=4539;
 i=fy15309206903@gmail.com; s=tbnet3; h=from:subject:message-id;
 bh=fu4XTpUKPy6Y/hy6UUuhAX/s9vCELgq4P3Cr6yC+8dQ=;
 b=0y9QRIafVvsV08ko7PuOE9LnR8SJbGYhY0IsYnH93PCWRMqTLiGbys5e0swK+ulqT/vMyIvpE
 yzvOAj79grhBaFi5+VL1ztqNy8hQQhnN8eS6ReP6jQa07kZXbOqNRkH
X-Developer-Key: i=fy15309206903@gmail.com; a=ed25519;
 pk=6QsQIrI/kruYWIJyCH9ntPMXsHCqF5JtK/DCMtOCzdc=
X-Endpoint-Received: by B4 Relay for fy15309206903@gmail.com/tbnet3 with auth_id=929
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

smp_mb__before_atomic() only orders against a non-value-returning atomic
RMW that follows it.  test_bit() is a plain load, so under the LKMM this
fence orders nothing here and nothing may rely on it.  It is not free
either: only six architectures override __smp_mb__before_atomic, so on
arm64 and most others it emits a real barrier -- dropping it removes one
dmb ish from each of the two inlined call sites.  The ordering the
comment asks for does not come from the fence in the first place; see
below.

It did not start out this way.  commit f1ebcc74d5b2 ("Btrfs: fix tree
corruption after multi-thread snapshots and inode_cache flush") added it
as a real smp_rmb(), paired with smp_wmb() around a plain int force_cow.
commit d1980131ca7f ("btrfs: update barrier in should_cow_block") swapped
it for smp_mb__before_atomic() when the field became a bit, noting in
its own log that "we should be fine in case the atomic barrier becomes a
no-op" -- and against a plain test_bit() that is what it became.
commit f07575bab632 ("btrfs: make the rule checking more readable for
should_cow_block()") only relocated it.  Drop it along with the comment
rather than promote it to a real barrier: whatever ordering is wanted
here would have to name what it pairs with today.  The two writer-side
comments in transaction.c only pointed here for that rationale, so they
go with it; the smp_mb__after_atomic() they annotated is left alone.

Assisted-by: Claude:claude-opus-5 sashiko(Sonnet-5) qwen
Signed-off-by: FAN YE <fy15309206903@gmail.com>
---
Why the ordering does not depend on the fence: any writer that can reach
should_cow_block() for this root crosses fs_info->trans_lock in
join_transaction(), and can only do so after the committer's matching
unlock when it leaves TRANS_STATE_COMMIT_DOING in
btrfs_commit_transaction(), by which point create_pending_snapshots() --
where set_bit(FORCE_COW) lives -- has already run.  That release/acquire
pair orders the bit, fence or not.  BTRFS_ROOT_FORCE_COW has only these
three references tree-wide.

herd7 with the LKMM, one SB shape with only the fence varying: allowed with
this fence in front of a plain load, still allowed with the fence deleted,
forbidden with smp_mb() and forbidden with an RMW after the fence.  Built
with klitmus7 on x86_64 it hits 329608 times in 64000000 iterations, 329706
with the fence deleted, 0 with smp_mb().

arm64 defconfig+BTRFS_FS, gcc 13.3: ctree.o goes from 39 to 37 dmb ish, one
each from btrfs_cow_block() and btrfs_search_slot().  On x86_64 .text is
unchanged -- the only object differences are __LINE__ constants in the BUG
table shifting by the two deleted lines.  Compile-tested W=1 on both.

Sent as RFC for the one thing this does not settle: with the reader side
gone, the smp_mb__after_atomic() on each writer has nothing left to pair
with, and by the argument above trans_lock was doing the work anyway.  I
left both alone rather than guess -- if they are stale too that is a
separate patch, and I would rather have your reading first.
---
 fs/btrfs/ctree.c       | 2 --
 fs/btrfs/transaction.c | 2 --
 2 files changed, 4 deletions(-)

diff --git a/fs/btrfs/ctree.c b/fs/btrfs/ctree.c
index 8fe330d81b8f..fe74967d725a 100644
--- a/fs/btrfs/ctree.c
+++ b/fs/btrfs/ctree.c
@@ -625,8 +625,6 @@ static inline bool should_cow_block(struct btrfs_trans_handle *trans,
 	if (btrfs_header_flag(buf, BTRFS_HEADER_FLAG_WRITTEN))
 		return true;
 
-	/* Ensure we can see the FORCE_COW bit. */
-	smp_mb__before_atomic();
 	if (test_bit(BTRFS_ROOT_FORCE_COW, &root->state))
 		return true;
 
diff --git a/fs/btrfs/transaction.c b/fs/btrfs/transaction.c
index bafc62cf5ebc..3fced11d7889 100644
--- a/fs/btrfs/transaction.c
+++ b/fs/btrfs/transaction.c
@@ -1531,7 +1531,6 @@ static noinline int commit_fs_roots(struct btrfs_trans_handle *trans)
 			if (unlikely(ret2))
 				return ret2;
 
-			/* see comments in should_cow_block() */
 			clear_bit(BTRFS_ROOT_FORCE_COW, &root->state);
 			smp_mb__after_atomic();
 
@@ -1819,7 +1818,6 @@ static noinline int create_pending_snapshot(struct btrfs_trans_handle *trans,
 		btrfs_abort_transaction(trans, ret);
 		goto fail;
 	}
-	/* see comments in should_cow_block() */
 	set_bit(BTRFS_ROOT_FORCE_COW, &root->state);
 	smp_mb__after_atomic();
 

---
base-commit: 2709dd5ae32f0828f386327c76bba9f39f63a1c6
change-id: 20260823-btrfs-drop-ineffective-barrier-c3112e55b00b

Best regards,
--  
FAN YE <fy15309206903@gmail.com>

