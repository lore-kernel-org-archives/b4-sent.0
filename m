From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:02:53 +0800
Subject: [PATCH v6.6 4/4] vfs: support statx(..., NULL, AT_EMPTY_PATH, ...)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-6-6-y-v1-4-8731db3f4834@gmail.com>
References: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-6-6-y-v1-0-8731db3f4834@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, Miguel Ojeda <ojeda@kernel.org>, 
 Alex Gaynor <alex.gaynor@gmail.com>, 
 Wedson Almeida Filho <wedsonaf@gmail.com>, 
 Boqun Feng <boqun.feng@gmail.com>, Gary Guo <gary@garyguo.net>, 
 =?utf-8?q?Bj=C3=B6rn_Roy_Baron?= <bjorn3_gh@protonmail.com>, 
 Benno Lossin <benno.lossin@proton.me>, 
 Andreas Hindborg <a.hindborg@samsung.com>, 
 Alice Ryhl <aliceryhl@google.com>, stable@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=7983;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=dTLv45tt2cCUE7ZoLSxORuB/2l3oY6R2BAqvJxcMVXY=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t2Mr6jQ+GkPQJKKuGVWzi3ZqU9JwaC3gbqkW
 yFzK4mOtoqJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurdjAAKCRCwMePKe/7Z
 bqqGD/0fZmbVS8oBSTyjoiY9ljbo61x/etAmkiCE/tXL7VI5nhagPUael1pAP3pp6QxAQyU/mM8
 d7Dc4BUtdyEJHclZ2UeDZJfgzVfC9NwpYU4XiS+uqkpeKaYfOrh2lzyInjYqxR/w09agK7VKWj2
 dIS0Hm/Fqu9avrZpHcVu9a+X4clK26kWmRjxWWq/ASrN9Susr2jHpKpspN4WVaA+bhJ6z3S4arR
 vhkAvIdGJIEaJNlm7cV8YpIj90y86kIOaQeNz92Q6so36A8neF3QzFRHav1FPRpolGhsD2kGyu5
 sbIwxKati/2X/UTk7vt4nlpsUDeWOSWuusyxtSj0mbji4YTGQo8pes/S73ugTdMrCN7rOpZYP30
 LDRaKO8Z7/TLgKytJNKJxOZwsiAA3x/5vWa5giuC9fa900m2XeEBPaCwYSrDVq9ghq4LWm6HJbS
 enyQPHFFGFLOnsvB9ZbDBJZDykU7M/WJlIX2m3CDWJ2OrNkIGdsJqjKhammAVPV6a5heFB0lac6
 HRe7BubIl6MOakkNmfh3cRRMGvHgzKJNE1R5EJe860LvfMd1fjMkwTAagfWwe6ucHckd7o5AFz0
 3xkAUdAOtUMo87+Iwkdn9weOa3NhLgTu4/h+e5dR9mQg1Jaa6rOfrrmXJgtmB00Wg/EubnHvO+5
 DZzjMOut0kdZLdw==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/default with auth_id=189
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Mateusz Guzik <mjguzik@gmail.com>

commit 0ef625b upstream.

The newly used helper also checks for empty ("") paths.

NULL paths with any flag value other than AT_EMPTY_PATH go the usual
route and end up with -EFAULT to retain compatibility (Rust is abusing
calls of the sort to detect availability of statx).

This avoids path lookup code, lockref management, memory allocation and
in case of NULL path userspace memory access (which can be quite
expensive with SMAP on x86_64).

Benchmarked with statx(..., AT_EMPTY_PATH, ...) running on Sapphire
Rapids, with the "" path for the first two cases and NULL for the last
one.

Results in ops/s:
stock:     4231237
pre-check: 5944063 (+40%)
NULL path: 6601619 (+11%/+56%)

Signed-off-by: Mateusz Guzik <mjguzik@gmail.com>
Link: https://lore.kernel.org/r/20240625151807.620812-1-mjguzik@gmail.com
Tested-by: Xi Ruoyao <xry111@xry111.site>
[brauner: use path_mounted() and other tweaks]
Signed-off-by: Christian Brauner <brauner@kernel.org>

Cc: <stable@vger.kernel.org> # 6.6.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/internal.h  |  14 ++++++++
 fs/namespace.c |  13 --------
 fs/stat.c      | 101 ++++++++++++++++++++++++++++++++++++++++++++-------------
 3 files changed, 92 insertions(+), 36 deletions(-)

diff --git a/fs/internal.h b/fs/internal.h
index d64ae03998cc..ac775b2316d5 100644
--- a/fs/internal.h
+++ b/fs/internal.h
@@ -231,6 +231,8 @@ extern const struct dentry_operations ns_dentry_operations;
 int getname_statx_lookup_flags(int flags);
 int do_statx(int dfd, struct filename *filename, unsigned int flags,
 	     unsigned int mask, struct statx __user *buffer);
+int do_statx_fd(int fd, unsigned int flags, unsigned int mask,
+		struct statx __user *buffer);
 
 /*
  * fs/splice.c:
@@ -298,3 +300,15 @@ ssize_t __kernel_write_iter(struct file *file, struct iov_iter *from, loff_t *po
 struct mnt_idmap *alloc_mnt_idmap(struct user_namespace *mnt_userns);
 struct mnt_idmap *mnt_idmap_get(struct mnt_idmap *idmap);
 void mnt_idmap_put(struct mnt_idmap *idmap);
+/**
+ * path_mounted - check whether path is mounted
+ * @path: path to check
+ *
+ * Determine whether @path refers to the root of a mount.
+ *
+ * Return: true if @path is the root of a mount, false if not.
+ */
+static inline bool path_mounted(const struct path *path)
+{
+	return path->mnt->mnt_root == path->dentry;
+}
diff --git a/fs/namespace.c b/fs/namespace.c
index e6c61d4997cc..3c79fb8f94e8 100644
--- a/fs/namespace.c
+++ b/fs/namespace.c
@@ -1844,19 +1844,6 @@ bool may_mount(void)
 	return ns_capable(current->nsproxy->mnt_ns->user_ns, CAP_SYS_ADMIN);
 }
 
-/**
- * path_mounted - check whether path is mounted
- * @path: path to check
- *
- * Determine whether @path refers to the root of a mount.
- *
- * Return: true if @path is the root of a mount, false if not.
- */
-static inline bool path_mounted(const struct path *path)
-{
-	return path->mnt->mnt_root == path->dentry;
-}
-
 static void warn_mandlock(void)
 {
 	pr_warn_once("=======================================================\n"
diff --git a/fs/stat.c b/fs/stat.c
index 045b2a02de50..aa91363342be 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -214,6 +214,38 @@ int getname_statx_lookup_flags(int flags)
 	return lookup_flags;
 }
 
+static int vfs_statx_path(struct path *path, int flags, struct kstat *stat,
+			  u32 request_mask)
+{
+	int error = vfs_getattr(path, stat, request_mask, flags);
+
+	stat->mnt_id = real_mount(path->mnt)->mnt_id;
+	stat->result_mask |= STATX_MNT_ID;
+
+	if (path_mounted(path))
+		stat->attributes |= STATX_ATTR_MOUNT_ROOT;
+	stat->attributes_mask |= STATX_ATTR_MOUNT_ROOT;
+
+	/* Handle STATX_DIOALIGN for block devices. */
+	if (request_mask & STATX_DIOALIGN) {
+		struct inode *inode = d_backing_inode(path->dentry);
+
+		if (S_ISBLK(inode->i_mode))
+			bdev_statx_dioalign(inode, stat);
+	}
+
+	return error;
+}
+
+static int vfs_statx_fd(int fd, int flags, struct kstat *stat,
+			  u32 request_mask)
+{
+	CLASS(fd_raw, f)(fd);
+	if (!f.file)
+		return -EBADF;
+	return vfs_statx_path(&f.file->f_path, flags, stat, request_mask);
+}
+
 /**
  * vfs_statx - Get basic and extra attributes by filename
  * @dfd: A file descriptor representing the base dir for a relative filename
@@ -243,31 +275,13 @@ static int vfs_statx(int dfd, struct filename *filename, int flags,
 retry:
 	error = filename_lookup(dfd, filename, lookup_flags, &path, NULL);
 	if (error)
-		goto out;
-
-	error = vfs_getattr(&path, stat, request_mask, flags);
-
-	stat->mnt_id = real_mount(path.mnt)->mnt_id;
-	stat->result_mask |= STATX_MNT_ID;
-
-	if (path.mnt->mnt_root == path.dentry)
-		stat->attributes |= STATX_ATTR_MOUNT_ROOT;
-	stat->attributes_mask |= STATX_ATTR_MOUNT_ROOT;
-
-	/* Handle STATX_DIOALIGN for block devices. */
-	if (request_mask & STATX_DIOALIGN) {
-		struct inode *inode = d_backing_inode(path.dentry);
-
-		if (S_ISBLK(inode->i_mode))
-			bdev_statx_dioalign(inode, stat);
-	}
-
+		return error;
+	error = vfs_statx_path(&path, flags, stat, request_mask);
 	path_put(&path);
 	if (retry_estale(error, lookup_flags)) {
 		lookup_flags |= LOOKUP_REVAL;
 		goto retry;
 	}
-out:
 	return error;
 }
 
@@ -660,7 +674,8 @@ int do_statx(int dfd, struct filename *filename, unsigned int flags,
 	if ((flags & AT_STATX_SYNC_TYPE) == AT_STATX_SYNC_TYPE)
 		return -EINVAL;
 
-	/* STATX_CHANGE_COOKIE is kernel-only for now. Ignore requests
+	/*
+	 * STATX_CHANGE_COOKIE is kernel-only for now. Ignore requests
 	 * from userland.
 	 */
 	mask &= ~STATX_CHANGE_COOKIE;
@@ -672,16 +687,41 @@ int do_statx(int dfd, struct filename *filename, unsigned int flags,
 	return cp_statx(&stat, buffer);
 }
 
+int do_statx_fd(int fd, unsigned int flags, unsigned int mask,
+	     struct statx __user *buffer)
+{
+	struct kstat stat;
+	int error;
+
+	if (mask & STATX__RESERVED)
+		return -EINVAL;
+	if ((flags & AT_STATX_SYNC_TYPE) == AT_STATX_SYNC_TYPE)
+		return -EINVAL;
+
+	/*
+	 * STATX_CHANGE_COOKIE is kernel-only for now. Ignore requests
+	 * from userland.
+	 */
+	mask &= ~STATX_CHANGE_COOKIE;
+
+	error = vfs_statx_fd(fd, flags, &stat, mask);
+	if (error)
+		return error;
+
+	return cp_statx(&stat, buffer);
+}
+
 /**
  * sys_statx - System call to get enhanced stats
  * @dfd: Base directory to pathwalk from *or* fd to stat.
- * @filename: File to stat or "" with AT_EMPTY_PATH
+ * @filename: File to stat or either NULL or "" with AT_EMPTY_PATH
  * @flags: AT_* flags to control pathwalk.
  * @mask: Parts of statx struct actually required.
  * @buffer: Result buffer.
  *
  * Note that fstat() can be emulated by setting dfd to the fd of interest,
- * supplying "" as the filename and setting AT_EMPTY_PATH in the flags.
+ * supplying "" (or preferably NULL) as the filename and setting AT_EMPTY_PATH
+ * in the flags.
  */
 SYSCALL_DEFINE5(statx,
 		int, dfd, const char __user *, filename, unsigned, flags,
@@ -689,8 +729,23 @@ SYSCALL_DEFINE5(statx,
 		struct statx __user *, buffer)
 {
 	int ret;
+	unsigned lflags;
 	struct filename *name;
 
+	/*
+	 * Short-circuit handling of NULL and "" paths.
+	 *
+	 * For a NULL path we require and accept only the AT_EMPTY_PATH flag
+	 * (possibly |'d with AT_STATX flags).
+	 *
+	 * However, glibc on 32-bit architectures implements fstatat as statx
+	 * with the "" pathname and AT_NO_AUTOMOUNT | AT_EMPTY_PATH flags.
+	 * Supporting this results in the uglification below.
+	 */
+	lflags = flags & ~(AT_NO_AUTOMOUNT | AT_STATX_SYNC_TYPE);
+	if (lflags == AT_EMPTY_PATH && vfs_empty_path(dfd, filename))
+		return do_statx_fd(dfd, flags & ~AT_NO_AUTOMOUNT, mask, buffer);
+
 	name = getname_flags(filename, getname_statx_lookup_flags(flags), NULL);
 	ret = do_statx(dfd, name, flags, mask, buffer);
 	putname(name);

-- 
2.43.0

