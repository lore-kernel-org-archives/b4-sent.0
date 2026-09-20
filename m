From: Florian Schmaus <flo@geekplace.eu>
Date: Sun, 20 Sep 2026 16:35:25 +0200
Subject: [PATCH] PM: hibernate: Freeze kernel threads after image
 preallocation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260920-fix-hibernation-v1-1-f9940c2d7d7f@geekplace.eu>
X-B4-Tracking: v=1; b=H4sIACzvr2oC/yWMQQ5AMBAAvyJ71qQVrfAVcaharENJi0gaf7c4T
 jIzCSIGwghNliDgSZFWz6DyDNxs/YSCBmYoZGFkrbQY6RIz9Ri83dkV1g516VBVWhrgagvIynd
 su5/j0S/o9ncD9/0A5Jq7kXMAAAA=
X-Change-ID: 20260915-fix-hibernation-aad94ce17506
To: "Rafael J. Wysocki" <rafael@kernel.org>, 
 Pavel Machek <pavel@kernel.org>, Len Brown <lenb@kernel.org>, 
 Matthew Leach <matthew.leach@collabora.com>, 
 "Mario Limonciello (AMD)" <superm1@kernel.org>
Cc: "Rafael J. Wysocki" <rafael.j.wysocki@intel.com>, 
 linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Florian Schmaus <flo@geekplace.eu>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4366; i=flo@geekplace.eu;
 h=from:subject:message-id; bh=ysUjw7z8QALgGHyL8R2OnkKc9GGo433dXMNEgZG0j9g=;
 b=owGbwMvMwMWoZLn8xddWhSDG02pJDFnr3+vKXDrZmbbZ5d2iivii/jiJR0yMDsxXzrYJyM268
 N74pvjcTsb1LAyMXAwzxRRZppeyzrdSvPMw+8nvdTCDWJlApkiLNDAAAQsDX25iXqmRjpGeqbah
 niGQoWMUD5HTY9DILC4uTS3STSsocsjLL0ksyczPK9bLL0jNK0gv0EvLTCvJyMgvKk4FGqGXl1p
 iaW5uamBq6WbsaGTo4uxqaObkauLm5OhqZGRs6WjuauFmamFqZGBqxMDFKQBzzYwc9v+e+V19am
 13Ps69tK6zu96VV0I0fc0y4ZyLYrIXgrq2vZ2kpyG/YMPOB5KSETqrWja+k+Juf9swM+hBngS7w
 EGtJR++1zd6rtd5+2xOoO6V149cLB5nZe5h/JzNbCf7W+nxoai0PeKq5TnqqXdepFhNDttTvuo7
 n8W2tAMXnrNpHEl9wL7OOmHl7dMsbNlBlxbydnIn12xf2Lfe8/Kzgirf+cLNUjy703JkORtK9nz
 Q+yGRMn3h9dnh1mLJEvnzb9y5oPn/1OGULfpX1t9oS9IostT84/DyW8TeT2rOrLsXztcsPP1g/+
 aX4Sn8V71yo4NndSz4dVCj7M6TV93a1jEencJf/bs+/lp6fuJRHXMA
X-Developer-Key: i=flo@geekplace.eu; a=openpgp;
 fpr=1357B01865B2503C18453D208CAC2A9678548E35
X-Endpoint-Received: by B4 Relay for flo@geekplace.eu/default with auth_id=792
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 783c81098445 ("PM: hibernate: call preallocate_image() after freeze
prepare") moved hibernate_preallocate_memory() after dpm_prepare() so
that device drivers have the opportunity to release pinned/unswappable
memory during their ->prepare() callback before memory is preallocated
for the snapshot image.

However, that commit also placed hibernate_preallocate_memory() after
freeze_kernel_threads(). While it was assumed during review that swap
I/O submitted via submit_bio() is synchronous and would not depend on
frozen kernel threads, this does not hold in practice. Calling
hibernate_preallocate_memory() with kernel threads frozen leads to
intermittent deadlocks during hibernation.

Inside hibernate_preallocate_memory(), shrink_all_memory() is invoked with
.may_writepage = 1 and .may_swap = 1 to aggressively reclaim and swap out
pages. Any writeback or swap I/O that relies on freezable kernel threads,
block device helpers, or WQ_FREEZABLE workqueues (such as those in storage
drivers, device mapper, or filesystems) deadlocks waiting on tasks that
are stuck in the refrigerator.

Fix this by reordering hibernation_snapshot():
1. Call dpm_prepare(PMSG_FREEZE) first, allowing device drivers to release
   pinned resources while kernel threads are still active.
2. Call hibernate_preallocate_memory() second, performing page reclaim and
   swapout while storage layers, workqueues, and kernel threads are alive.
3. Call freeze_kernel_threads() third, only after all memory preallocation
   and swap I/O have completed.

Additionally, restore the call to swsusp_free() in the cleanup path so
that preallocated image memory is properly freed if freeze_kernel_threads()
fails or if TEST_FREEZER is enabled.

Fixes: 783c81098445 ("PM: hibernate: call preallocate_image() after freeze prepare")
Signed-off-by: Florian Schmaus <flo@geekplace.eu>
---
During the review of commit 783c81098445 ("PM: hibernate: call
preallocate_image() after freeze prepare") [1], concerns were raised
regarding whether memory reclaim and swap I/O could deadlock if kernel
threads were already frozen.

At the time, it was thought that pageout to swap would not depend on
frozen threads. However, on Linux 7.2, I ran into reliable issues with
suspend-to-disk hanging during hibernation. Reordering the sequence so
that kernel threads are frozen after image preallocation (as done in
this patch) fixes the issue for me.

This patch restores the ordering where kernel threads are frozen only after
memory preallocation and swap I/O have completed, while keeping the
benefit of calling dpm_prepare() beforehand so drivers can release pinned
pages.

[1] https://patch.msgid.link/20260403-hibernation-fixes-v3-1-31bc9fa3ba2d@collabora.com
---
 kernel/power/hibernate.c | 26 ++++++++++++++------------
 1 file changed, 14 insertions(+), 12 deletions(-)

diff --git a/kernel/power/hibernate.c b/kernel/power/hibernate.c
index d2479c69d71a..c13f68ab7f6e 100644
--- a/kernel/power/hibernate.c
+++ b/kernel/power/hibernate.c
@@ -408,9 +408,18 @@ int hibernation_snapshot(int platform_mode)
 	if (error)
 		goto Close;
 
+	error = dpm_prepare(PMSG_FREEZE);
+	if (error)
+		goto Complete;
+
+	/* Preallocate image memory before freezing kernel threads and shutting down devices. */
+	error = hibernate_preallocate_memory();
+	if (error)
+		goto Complete;
+
 	error = freeze_kernel_threads();
 	if (error)
-		goto Close;
+		goto Cleanup;
 
 	if (hibernation_test(TEST_FREEZER)) {
 
@@ -422,15 +431,6 @@ int hibernation_snapshot(int platform_mode)
 		goto Thaw;
 	}
 
-	error = dpm_prepare(PMSG_FREEZE);
-	if (error)
-		goto Complete;
-
-	/* Preallocate image memory before shutting down devices. */
-	error = hibernate_preallocate_memory();
-	if (error)
-		goto Complete;
-
 	console_suspend_all();
 	pm_restrict_gfp_mask();
 
@@ -464,10 +464,12 @@ int hibernation_snapshot(int platform_mode)
 	platform_end(platform_mode);
 	return error;
 
- Complete:
-	dpm_complete(PMSG_RECOVER);
  Thaw:
 	thaw_kernel_threads();
+ Cleanup:
+	swsusp_free();
+ Complete:
+	dpm_complete(PMSG_RECOVER);
 	goto Close;
 }
 

---
base-commit: 40288c9206c17eb66a603262e06a58d300d0f279
change-id: 20260915-fix-hibernation-aad94ce17506

Best regards,
--  
Florian Schmaus <flo@geekplace.eu>

