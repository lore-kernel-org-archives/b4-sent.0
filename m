From: Luca Stefani <luca.stefani.ge1@gmail.com>
Date: Wed, 28 Oct 2026 18:55:50 +0100
Subject: [PATCH 2/2] btrfs: don't report failure when trim is interrupted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261028-b4-btrfs-fitrim-interruption-v1-2-bf5c53738b3a@gmail.com>
References: <20261028-b4-btrfs-fitrim-interruption-v1-0-bf5c53738b3a@gmail.com>
In-Reply-To: <20261028-b4-btrfs-fitrim-interruption-v1-0-bf5c53738b3a@gmail.com>
To: David Sterba <dsterba@suse.com>, Chris Mason <mason@kernel.org>, 
 Luca Stefani <luca.stefani.ge1@gmail.com>
Cc: Robbie Ko <robbieko@synology.com>, Filipe Manana <fdmanana@suse.com>, 
 linux-btrfs@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Zhiwei Liang <zhiwei.liang@zliang.me>, Qu Wenruo <wqu@suse.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793210149; l=1270;
 i=luca.stefani.ge1@gmail.com; s=20261028; h=from:subject:message-id;
 bh=SHRYs75MlS7h15FzpDG0vGMIMQ3guuhpE4HMc+f+OLg=;
 b=PqMIpIsvrDz40U2W8kqPvIIUiPvJl384C2hgujzHQfvCa78g9smaGobCvkjcJb5ARaj9kwnD4
 LtACyEsLihdAxU1shFVoLAH5KkOvKavqdgLPOLRFCW7Luu38T+iiiNz
X-Developer-Key: i=luca.stefani.ge1@gmail.com; a=ed25519;
 pk=0OIKU9oiaC0ALN4kqvw7ZbPFXqsBLvWm7MhEDYv3PyI=
X-Endpoint-Received: by B4 Relay for luca.stefani.ge1@gmail.com/20261028 with auth_id=1347
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Treat cancellation as a successful partial trim as ext4 and XFS do.

Reported-by: Zhiwei Liang <zhiwei.liang@zliang.me>
Closes: https://lore.kernel.org/20261028-btrfs-fitrim-freezer-v1-1-0ad1d58aa94d@zliang.me/
Suggested-by: Qu Wenruo <wqu@suse.com>
Signed-off-by: Luca Stefani <luca.stefani.ge1@gmail.com>
---
 fs/btrfs/extent-tree.c | 5 ++---
 1 file changed, 2 insertions(+), 3 deletions(-)

diff --git a/fs/btrfs/extent-tree.c b/fs/btrfs/extent-tree.c
index 242db255cf1c..90e581c29609 100644
--- a/fs/btrfs/extent-tree.c
+++ b/fs/btrfs/extent-tree.c
@@ -6926,7 +6926,7 @@ int btrfs_trim_fs(struct btrfs_fs_info *fs_info, struct fstrim_range *range)
 			bg_failed, ERR_PTR(bg_ret));
 
 	if (ret == -ERESTARTSYS || ret == -EINTR)
-		return ret;
+		goto out;
 
 	ret = btrfs_trim_free_extents(fs_info, &group_trimmed, &dev_failed, &dev_ret);
 	trimmed += group_trimmed;
@@ -6935,9 +6935,8 @@ int btrfs_trim_fs(struct btrfs_fs_info *fs_info, struct fstrim_range *range)
 		btrfs_warn(fs_info,
 			"failed to trim %llu device(s), first error %pe",
 			dev_failed, ERR_PTR(dev_ret));
+out:
 	range->len = trimmed;
-	if (ret == -ERESTARTSYS || ret == -EINTR)
-		return ret;
 	if (bg_ret)
 		return bg_ret;
 	return dev_ret;

-- 
2.56.0

