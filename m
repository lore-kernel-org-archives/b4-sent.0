From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:10:40 +0800
Subject: [PATCH v5.15-v5.10 4/4] vfs: support statx(..., NULL,
 AT_EMPTY_PATH, ...)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-15-y-v1-4-5afb4401ddbe@gmail.com>
References: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-15-y-v1-0-5afb4401ddbe@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Mateusz Guzik <mjguzik@gmail.com>, 
 Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=4898;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=OE5eWgqDbbcGmkrUd4eBvT4vTym9+pB223rJsVqpcEE=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t9oSJR2HVH8I9ryMHBIVdRQMzP0udOSKMrz3
 yNnic5aTiuJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurfaAAKCRCwMePKe/7Z
 brEGD/9+itzEZuJDXbNurtRve2swtSSlksFJktuKRGLiewwS70XydOAeWzsyDqPNQTaolDcp75S
 /WJ5u3elMF34kxCZcermuD95hhQuEiIDm9HtsyY3c2a+UZE9Az2rtF3MS/eFA4F0zfxlAKBstgb
 Yg6OrDSj7fFF1TgHi4nlBrOzY0JmRmjKyKeQ9Ge9ZB2VtgbkvSt1fc1+JIQDL6mCjenjKLZ6el7
 iqtVcoeLAofNekO5QIJO5x5DSl2hK2oPYygsqSG4mSKPKNth0gJXyowFya+7Z31/txUP/7GooD6
 ucQd4MeKxgNc1jSA2sjnKlV7UZqJQcGxQCUpnh3u0GUnnaLPajOWf2NFm2xn1PC0O3XXcRVKNIb
 oiLQzAqrUGnu9c/Nw9lz68qo2X6ix34iVsXiBfpFx8980BEVIstliUfHKy8vSrBV5KjLaQRSoVh
 geFAyY30jeOq5Jx8iHWhscQ4q5i78+C+iikgwTcPZwOjOsdpzL/WK+3FqG3U7Uxxcn77HKfnrjD
 XF522XTkpAKDWhLKUjxsDrLMtqyIA99iMave6AJPEe3m0rlcnrU8BxgN9ketV1AMWe6A90TXOuS
 LbPwl4a0MUCYym7jVMskKQE+WkoF3c/mjWvUxudrZouAD2qFrXg7DWKxzltoGa1cTDo8QKRZ+Py
 +7K985VA+e27zOg==
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

Cc: <stable@vger.kernel.org> # 5.10.x-5.15.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 64 +++++++++++++++++++++++++++++++++++++++++++++++++++------------
 1 file changed, 52 insertions(+), 12 deletions(-)

diff --git a/fs/stat.c b/fs/stat.c
index b8faa3f4b046..f02361a2ae54 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -184,6 +184,37 @@ int vfs_fstat(int fd, struct kstat *stat)
 	return error;
 }
 
+static int vfs_statx_path(struct path *path, int flags, struct kstat *stat,
+			  u32 request_mask)
+{
+	int error = vfs_getattr(path, stat, request_mask, flags);
+
+	stat->mnt_id = real_mount(path->mnt)->mnt_id;
+	stat->result_mask |= STATX_MNT_ID;
+	if (path->mnt->mnt_root == path->dentry)
+		stat->attributes |= STATX_ATTR_MOUNT_ROOT;
+	stat->attributes_mask |= STATX_ATTR_MOUNT_ROOT;
+
+	return error;
+}
+
+static int vfs_statx_fd(int fd, int flags, struct kstat *stat,
+			  u32 request_mask)
+{
+	int rc;
+	struct fd f = fdget_raw(fd);
+
+	if (!f.file) {
+		rc = -EBADF;
+		goto err;
+	}
+	rc = vfs_statx_path(&f.file->f_path, flags, stat, request_mask);
+
+err:
+	fdput(f);
+	return rc;
+}
+
 /**
  * vfs_statx - Get basic and extra attributes by filename
  * @dfd: A file descriptor representing the base dir for a relative filename
@@ -220,20 +251,13 @@ static int vfs_statx(int dfd, const char __user *filename, int flags,
 retry:
 	error = user_path_at(dfd, filename, lookup_flags, &path);
 	if (error)
-		goto out;
-
-	error = vfs_getattr(&path, stat, request_mask, flags);
-	stat->mnt_id = real_mount(path.mnt)->mnt_id;
-	stat->result_mask |= STATX_MNT_ID;
-	if (path.mnt->mnt_root == path.dentry)
-		stat->attributes |= STATX_ATTR_MOUNT_ROOT;
-	stat->attributes_mask |= STATX_ATTR_MOUNT_ROOT;
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
 
@@ -615,13 +639,28 @@ int do_statx(int dfd, const char __user *filename, unsigned flags,
 {
 	struct kstat stat;
 	int error;
+	unsigned lflags;
 
 	if (mask & STATX__RESERVED)
 		return -EINVAL;
 	if ((flags & AT_STATX_SYNC_TYPE) == AT_STATX_SYNC_TYPE)
 		return -EINVAL;
 
-	error = vfs_statx(dfd, filename, flags, &stat, mask);
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
+		error = vfs_statx_fd(dfd, flags & ~AT_NO_AUTOMOUNT, &stat, mask);
+	else
+		error = vfs_statx(dfd, filename, flags, &stat, mask);
 	if (error)
 		return error;
 
@@ -631,13 +670,14 @@ int do_statx(int dfd, const char __user *filename, unsigned flags,
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

-- 
2.43.0

