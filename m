From: Bernd Schubert <bernd@bsbernd.com>
Date: Wed, 30 Sep 2026 15:44:33 +0200
Subject: [PATCH 1/4] mount_fsmount: split superblock creation and
 move_mount into a helper
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-mount-service-use-mount-fsmount-v1-1-d585598896ee@bsbernd.com>
References: <20260930-mount-service-use-mount-fsmount-v1-0-d585598896ee@bsbernd.com>
In-Reply-To: <20260930-mount-service-use-mount-fsmount-v1-0-d585598896ee@bsbernd.com>
To: "Darrick J. Wong" <djwong@kernel.org>
Cc: neal@gompa.dev, fuse-devel@lists.linux.dev, 
 Bernd Schubert <bernd@bsbernd.com>
X-Mailer: b4 0.16-dev-d5d98
X-Developer-Signature: v=1; a=openpgp-sha256; l=5634; i=bernd@bsbernd.com;
 h=from:subject:message-id; bh=xzRxuwa63Vh0hWGAVlL/J9Afa2FZo54hNpLnXTUqna0=;
 b=owGbwMvMwCFm9Dnz3fRepz+Mp9WSGLL2Cvnw/1Ps434x0aYkw/iARm5WYZLw8qWFMeZ/Nb6k/
 Qsp2xPfUcrCIMbBICumyNIlscd2yj8+WbWv66/DzGFlAhnCwMUpABNRM2T4p7PF75REwgvpp3H5
 D+8/YshneikcK9+X7hYmz3jxUnvhG4a/cvfkNWNkLV8qzFp91aD14ZV0RXcRhi9Keqr8T1XzvJL
 ZAQ==
X-Developer-Key: i=bernd@bsbernd.com; a=openpgp;
 fpr=8A18BC3D94FE0E1D26F5AFD732F369EE978D42FC
X-Endpoint-Received: by B4 Relay for bernd@bsbernd.com/default with auth_id=772
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a preparation patch. fuse_kern_fsmount() ran fsconfig
CREATE, fsmount() and move_mount() inline. A later commit will make
mount_service.c call the same three calls after it has run FSOPEN,
SOURCE and MNTOPTS itself, so this moves them into
fuse_fsmount_create_and_move(). The fsopen fd stays owned by the
caller, because mount_service.c will close mo->fsopenfd itself
later.

fuse_kern_fsmount() now converts MS_* flags before calling the
helper, so unsupported flags are caught before the superblock is
created, not after.

Signed-off-by: Bernd Schubert <bernd@bsbernd.com>
---
 lib/mount_fsmount.c | 86 +++++++++++++++++++++++++++++++----------------------
 lib/mount_i_linux.h | 18 +++++++++++
 2 files changed, 69 insertions(+), 35 deletions(-)

diff --git a/lib/mount_fsmount.c b/lib/mount_fsmount.c
index b2d0453e5c93..0b1fd4300d2d 100644
--- a/lib/mount_fsmount.c
+++ b/lib/mount_fsmount.c
@@ -489,6 +489,53 @@ void fuse_kern_umount_mountfd(int mountfd)
 	}
 }
 
+int fuse_fsmount_create_and_move(int fsfd, unsigned int mount_attrs,
+				 int dest_mnt_fd, const char *dest_path,
+				 int *mountfd_out)
+{
+	int mountfd;
+	int res;
+
+	res = fuse_fsconfig(fsfd, FSCONFIG_CMD_CREATE, NULL, NULL, 0);
+	if (res == -1) {
+		int save_errno = errno;
+
+		log_fsconfig_kmsg(fsfd);
+		fuse_log(FUSE_LOG_ERR, "fuse: fsconfig CREATE failed: %s\n",
+			 strerror(save_errno));
+		return -save_errno;
+	}
+
+	mountfd = fuse_fsmount(fsfd, FSMOUNT_CLOEXEC, mount_attrs);
+	if (mountfd == -1) {
+		int save_errno = errno;
+
+		log_fsconfig_kmsg(fsfd);
+		fuse_log(FUSE_LOG_ERR, "fuse: fsmount failed: %s\n",
+			 strerror(save_errno));
+		return -save_errno;
+	}
+
+	if (dest_mnt_fd >= 0)
+		res = fuse_move_mount(mountfd, "", dest_mnt_fd, "",
+				      MOVE_MOUNT_F_EMPTY_PATH |
+					      MOVE_MOUNT_T_EMPTY_PATH);
+	else
+		res = fuse_move_mount(mountfd, "", AT_FDCWD, dest_path,
+				      MOVE_MOUNT_F_EMPTY_PATH);
+	if (res == -1) {
+		int save_errno = errno;
+
+		fuse_log(FUSE_LOG_ERR, "fuse: move_mount failed: %s\n",
+			 strerror(save_errno));
+		close(mountfd);
+		return -save_errno;
+	}
+
+	*mountfd_out = mountfd;
+	return 0;
+}
+
 int fuse_kern_fsmount(const char *mnt, int dest_mnt_fd, unsigned long flags,
 		      int blkdev, const char *fsname, const char *subtype,
 		      const char *source_dev, const char *kernel_opts,
@@ -584,16 +631,6 @@ int fuse_kern_fsmount(const char *mnt, int dest_mnt_fd, unsigned long flags,
 		goto out_free;
 	}
 
-	/* Create the filesystem instance */
-	res = fuse_fsconfig(fsfd, FSCONFIG_CMD_CREATE, NULL, NULL, 0);
-	if (res == -1) {
-		err = -errno;
-		log_fsconfig_kmsg(fsfd);
-		fuse_log(FUSE_LOG_ERR, "fuse: fsconfig CREATE failed: %s\n",
-			 strerror(errno));
-		goto out_free;
-	}
-
 	/* Convert MS_* flags to MOUNT_ATTR_* for fsmount() */
 	flags = ms_flags_to_mount_attrs(flags, &mount_attrs);
 	if (flags != 0) {
@@ -602,33 +639,14 @@ int fuse_kern_fsmount(const char *mnt, int dest_mnt_fd, unsigned long flags,
 		goto out_free;
 	}
 
-	/* Create mount object with mount attributes */
-	mountfd = fuse_fsmount(fsfd, FSMOUNT_CLOEXEC, mount_attrs);
-	if (mountfd == -1) {
-		err = -errno;
-		log_fsconfig_kmsg(fsfd);
-		fuse_log(FUSE_LOG_ERR, "fuse: fsmount failed: %s\n",
-			 strerror(errno));
+	err = fuse_fsmount_create_and_move(fsfd, mount_attrs, dest_mnt_fd, mnt,
+					   &mountfd);
+	if (err)
 		goto out_free;
-	}
 
 	close(fsfd);
 	fsfd = -1;
 
-	if (dest_mnt_fd >= 0)
-		res = fuse_move_mount(mountfd, "", dest_mnt_fd, "",
-				 MOVE_MOUNT_F_EMPTY_PATH |
-					 MOVE_MOUNT_T_EMPTY_PATH);
-	else
-		res = fuse_move_mount(mountfd, "", AT_FDCWD, mnt,
-				 MOVE_MOUNT_F_EMPTY_PATH);
-	if (res == -1) {
-		err = -errno;
-		fuse_log(FUSE_LOG_ERR, "fuse: move_mount failed: %s\n",
-			 strerror(errno));
-		goto out_close_mntfd;
-	}
-
 	res = fuse_mnt_add_mount_helper(mnt, source, type, mtab_opts);
 	if (res == -1) {
 		err = -EIO;
@@ -645,9 +663,7 @@ int fuse_kern_fsmount(const char *mnt, int dest_mnt_fd, unsigned long flags,
 
 out_umount:
 	fuse_kern_umount_mountfd(mountfd);
-out_close_mntfd:
-	if (mountfd != -1)
-		close(mountfd);
+	close(mountfd);
 out_free:
 	free(source);
 	free(type);
diff --git a/lib/mount_i_linux.h b/lib/mount_i_linux.h
index 8cf7ff4532c6..35bb54c82236 100644
--- a/lib/mount_i_linux.h
+++ b/lib/mount_i_linux.h
@@ -86,6 +86,24 @@ int fuse_kern_fsmount(const char *mnt, int mnt_fd, unsigned long flags,
 int fuse_kern_fsmount_mo(const char *mnt, const struct mount_opts *mo,
 			 const char *mtab_opts, int *mountfd_out);
 
+/**
+ * Create the superblock and attach the resulting mount to a destination.
+ *
+ * The fsopen fd stays owned by the caller - a caller that keeps it in
+ * long-lived state must not be left with a descriptor closed behind its back.
+ *
+ * @fsfd fsopen fd, fully configured
+ * @mount_attrs MOUNT_ATTR_* flags, from ms_flags_to_mount_attrs()
+ * @dest_mnt_fd pre-resolved destination fd, or -1 to use @dest_path
+ * @dest_path destination path, used only when @dest_mnt_fd is -1
+ * @mountfd_out on success receives the fsmount() fd, to be closed by the
+ *              caller and usable for fuse_kern_umount_mountfd()
+ * @return 0 on success, negative error code on failure
+ */
+int fuse_fsmount_create_and_move(int fsfd, unsigned int mount_attrs,
+				 int dest_mnt_fd, const char *dest_path,
+				 int *mountfd_out);
+
 /**
  * Unmount (lazily) the mount @mountfd was created for, without a path lookup.
  *

-- 
2.53.0

