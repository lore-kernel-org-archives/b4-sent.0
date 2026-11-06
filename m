From: incharilla <incharilla@incharilla.site>
Date: Fri, 06 Nov 2026 19:20:08 +0100
Subject: [PATCH] md: dont warn about sb update on auto read only arrays
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261106-md-auto-read-only-sb-warn-v1-1-5bfde3559841@incharilla.site>
X-B4-Tracking: v=1; b=H4sIAFca7moC/x3MTQqDMBBA4avIrDuQqIzYq5Quohl1wCZl4k+Le
 HeDy2/x3gGJVTjBszhAeZMkMWTYRwH95MLIKD4bSlOStYbw49GtS0Rl5zGG+Y+pw91pwKavPFH
 dGqoryP1XeZDf/X69z/MCqaYV42sAAAA=
X-Change-ID: 20261106-md-auto-read-only-sb-warn-7c3d66490643
To: Song Liu <song@kernel.org>, Yu Kuai <yukuai@fygo.io>, 
 Li Nan <magiclinan@didiglobal.com>, Xiao Ni <xiao@kernel.org>
Cc: Yu Kuai <yukuai@fnnas.com>, Corey Hickey <bugfood-c@fatooh.org>, 
 linux-raid@vger.kernel.org, linux-kernel@vger.kernel.org, 
 incharilla <incharilla@incharilla.site>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793989253; l=2603;
 i=incharilla@incharilla.site; s=20261106; h=from:subject:message-id;
 bh=+Wd6+KQm8viRtD/x34JdBjsIzmmj3vcZRVUKHpYuaGI=;
 b=ipL8t19JS3Mm0slekkicOmxJ0gwtSHfF1GGUH3z36OC+7GEwiABPyFZ3R6wIfsRRw+5JQ9BP8
 UGFQCnt/q1CANoKkBDYueW4IXWCsQM3WL9c2u9Zh5cFTno706XykKj3
X-Developer-Key: i=incharilla@incharilla.site; a=ed25519;
 pk=xE5D6YKyyCtab6ZeeJEA15KoJWTPKAxBRXCtRrslYk4=
X-Endpoint-Received: by B4 Relay for incharilla@incharilla.site/20261106 with auth_id=1436
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 8c9e376b9d1a ("md: warn about updating super block failure") added
an error when md_update_sb is called on a read only array to help debug io
hangs.

An array that is started auto read only prints this error for no reason.
This happens when it is assembled with start_ro set or when a degraded
array is created with start_ro set. md_update_sb already defers the
update by setting MD_SB_CHANGE_DEVS and the sb is written as soon as the
first write makes the array read write. No io can hang on an array that
has not been written to yet.

Skip the message for MD_AUTO_READ the same way dm raid is already skipped.
It is still printed for arrays that are really read only.

Tested in qemu on loop devices with raid1 and raid5 and raid10. Before
this patch assembling a clean array with start_ro set prints the error
for all three levels. Creating a degraded array with start_ro set prints
it in 5 of 10 tries for raid1 and 8 of 10 for raid5 and 4 of 10 for
raid10. After this patch none of these print it. On raid1 the first write
still makes the array read write and the sb events go from 17 to 19.
Assembling with mdadm --readonly still prints the error.

The fix and the qemu test were made with help from Claude Code.

Fixes: 8c9e376b9d1a ("md: warn about updating super block failure")
Reported-by: Corey Hickey <bugfood-c@fatooh.org>
Closes: https://bugzilla.kernel.org/show_bug.cgi?id=222162
Signed-off-by: incharilla <incharilla@incharilla.site>
---
Found from bugzilla 222162. The qemu test script used is a busybox
initramfs that creates raid1 and raid5 and raid10 arrays on loop devices
with start_ro set and counts the message in dmesg.
---
 drivers/md/md.c | 3 ++-
 1 file changed, 2 insertions(+), 1 deletion(-)

diff --git a/drivers/md/md.c b/drivers/md/md.c
index 03e35386a80283032e317e037a749eca23ce170e..a0fc6028990530026404f0019a458dfabed02349 100644
--- a/drivers/md/md.c
+++ b/drivers/md/md.c
@@ -2819,7 +2819,8 @@ void md_update_sb(struct mddev *mddev, int force_change)
 	if (!md_is_rdwr(mddev)) {
 		if (force_change)
 			set_bit(MD_SB_CHANGE_DEVS, &mddev->sb_flags);
-		if (!mddev_is_dm(mddev))
+		/* auto read only arrays write the sb once they become writable */
+		if (!mddev_is_dm(mddev) && mddev->ro != MD_AUTO_READ)
 			pr_err_ratelimited("%s: can't update sb for read-only array %s\n",
 					   __func__, mdname(mddev));
 		return;

---
base-commit: a91337fb5e8e0127c8b5be87be9f3027f95b48bc
change-id: 20261106-md-auto-read-only-sb-warn-7c3d66490643

Best regards,
-- 
incharilla <incharilla@incharilla.site>

