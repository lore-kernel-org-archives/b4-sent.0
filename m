From: Miao Wang <shankerwangmiao@gmail.com>
Date: Wed, 18 Sep 2024 22:12:25 +0800
Subject: [PATCH v5.4-v4.19 6/6] vfs: support statx(..., NULL,
 AT_EMPTY_PATH, ...)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240918-statx-stable-linux-5-4-y-v1-6-8a771c9bbe5f@gmail.com>
References: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
In-Reply-To: <20240918-statx-stable-linux-5-4-y-v1-0-8a771c9bbe5f@gmail.com>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, stable@vger.kernel.org
Cc: Xi Ruoyao <xry111@xry111.site>, Christian Brauner <brauner@kernel.org>, 
 Alexander Viro <viro@zeniv.linux.org.uk>, linux-fsdevel@vger.kernel.org, 
 stable@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>, 
 Mateusz Guzik <mjguzik@gmail.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=3164;
 i=shankerwangmiao@gmail.com; h=from:subject:message-id;
 bh=Mz70ynn0QmOv4iQYlvx/dmX1Pkma9wGWlUEA7jcK4og=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBm6t/dGuOjI9aYmI1LQfgwrbw0dZPMapB67Fl5U
 Px5kKe2npWJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCZurf3QAKCRCwMePKe/7Z
 bh8DD/9HS5BdVsTPeo/HHJUotxCRxYTUhGJighDBkTNcGK0dO63iAVafsGuImCuoSdjKdvUC9rE
 3TRGLdB+VaxHyxnCcSfxDuXeIIS+CUBLcvI1oLAOOGgCNIN5r3gRUxLPnIeugyQ+awOZg3qHRko
 VJNHxjFtvW0AMI2Nj8XcEiC8b/vMFTiouia0Gx3K9hi9vDdgkVmRFKmtBsJDc1tQIw4I/QVXPTj
 y4hUXpHn6loOlcSBp1bOw40d+8kKWhsskqku3VqwIdMkV7J+QmjfhXaAXvRXWpncOcV7qAqP+cr
 FImQj89feRMFc+QGThtbz/VYqHgsxjXYIj1T6skMrfByzPVsgSC8B6JDl6HFAGe1p/zWEGBxY4X
 jf9ZG9Bv8JwBVylB1FxGklA+y71fXJ9tTpeCJMN6Y3/OTyYaytVNHmSBDNprppNrT+m8st8TQCk
 G6+rfxxkm0+Y2l0WenX+Z2mk1RxmVYmysNwEHvpLPhXbE0VGJXpjWqDbRhacKeyXzB5kBwYWNBk
 mdv2eqvr12fsi8tDXBgzFl3JxgSJrSxtHAykMiqon9Kee74M/7al1rWzt2oGQyM3Z7XXH31tDNH
 NBFp0zhz5heTqevgk4qLUifLEe4l+Mw/fK5GILEVdnp4Sst7608jqxzOLTAKHuWap8L/2Sn1udK
 jkaaUscsYWWbFGA==
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

Cc: <stable@vger.kernel.org> # 4.19.x-5.4.x
Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
Tested-by: Xi Ruoyao <xry111@xry111.site>
---
 fs/stat.c | 23 ++++++++++++++++++++---
 1 file changed, 20 insertions(+), 3 deletions(-)

diff --git a/fs/stat.c b/fs/stat.c
index 1aaa5d847db8..111443789ced 100644
--- a/fs/stat.c
+++ b/fs/stat.c
@@ -590,13 +590,14 @@ cp_statx(const struct kstat *stat, struct statx __user *buffer)
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
@@ -605,13 +606,29 @@ SYSCALL_DEFINE5(statx,
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
+		error = vfs_statx_fd(dfd, &stat, mask,
+				    flags & ~(AT_NO_AUTOMOUNT | AT_EMPTY_PATH));
+	else
+		error = vfs_statx(dfd, filename, flags, &stat, mask);
 	if (error)
 		return error;
 

-- 
2.43.0

