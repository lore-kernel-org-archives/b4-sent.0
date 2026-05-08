From: Bernd Schubert <bernd@bsbernd.com>
Date: Fri, 08 May 2026 18:39:10 +0200
Subject: [PATCH 07/10] mount: clarify kernel_opts vs mnt_opts vs flags in
 fuse_kern_fsmount
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260508-new-mount-fixes-and-tests-v1-7-c67a0893ddbc@bsbernd.com>
References: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
In-Reply-To: <20260508-new-mount-fixes-and-tests-v1-0-c67a0893ddbc@bsbernd.com>
To: fuse-devel@lists.linux.dev
Cc: "Darrick J. Wong" <djwong@kernel.org>, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1578; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=fYrCO7QwClI+MAevGUjaWRFadp556xK1scubr8X9n/Q=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGDL/Ca5r/v43g9k9445a+f/wid7CX/a8L1pj6V0j79bU9
 YD9RjJ7RykLgxgHg6yYIkuXxB7bKf/4ZNW+rr8OM4eVCWQIAxenAEzkwgxGho7QyqtVt2ewsrsm
 TIwvSg/SW3Ml7FDd4VP7fR7sl3qda8XIMOGkLOMjpccpHmaH2ZfE3+UN2rRTvM7u9vofF99HhD8
 y4AAA
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just code/API updates, as these mount options can be rather confusing.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/mount_i_linux.h | 13 ++++++++++---
 1 file changed, 10 insertions(+), 3 deletions(-)

diff --git a/lib/mount_i_linux.h b/lib/mount_i_linux.h
index ab83e30b..112c365e 100644
--- a/lib/mount_i_linux.h
+++ b/lib/mount_i_linux.h
@@ -36,13 +36,20 @@ int fuse_kern_mount_get_base_mnt_opts(const struct mount_opts *mo, char **mnt_op
 /**
  * Mount using the new Linux mount API (fsopen/fsconfig/fsmount/move_mount)
  * @mnt: mountpoint
- * @flags: mount flags (MS_NOSUID, MS_NODEV, etc.)
+ * @flags: MS_* bits (ro/rw, nosuid, nodev, sync, dirsync, ...) -
+ *         translated by set_ms_flags() into fsconfig(SET_FLAG) and/or
+ *         fsmount(MOUNT_ATTR_*); never carried via the strings below.
  * @blkdev: 1 for fuseblk, 0 for fuse
  * @fsname: filesystem name (or NULL)
  * @subtype: filesystem subtype (or NULL)
  * @source_dev: device name for building source string
- * @kernel_opts: kernel mount options string
- * @mnt_opts: additional mount options to pass to the kernel
+ * @kernel_opts: FUSE-kernel options parsed from -o args
+ *               (e.g. "allow_other,max_read=65536,default_permissions")
+ * @mnt_opts:    extras the caller layers on
+ *               (e.g. "fd=7,rootmode=40000,user_id=1000,group_id=1000")
+ *
+ * @kernel_opts and @mnt_opts are both applied via fsconfig() in order;
+ * overlap is tolerated.
  *
  * Returns: 0 on success, -1 on failure with errno set
  */

-- 
2.53.0

