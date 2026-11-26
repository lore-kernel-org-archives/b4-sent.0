From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:42 +0100
Subject: [PATCH RFC 2/9] sysctl: Add flags to struct ctl_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-2-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2378;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=DY+HxOzdABni9v9bD3uPkozrQ4a6lDrBzkd5JicpEjs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGLx4UEqP7piMBaHEE+9RcZmrKgPhodlz
 pGFsRexVh03CokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxiAAoJELqXzVK3
 lkFPfVcL/0pAjqZiTKzWf8xFC0+7EggYrREPyr1I/M0H1jeU6C+752/PYdLPZ/Qi1DjapjRR07v
 lm6q77XJNvQlPWQLp2pwvKxHT2wBdgHzz2eFLcKLJUrn32tCe+4C5hcIhbpfg5TtlNvGU/NPgcR
 knw9gOQ0ThC9BVdBQL6oYmVnladtmOovxEfxo1q/P819vOi6E6ThF6wBNzRXZV6/Z4SGVpKIKx/
 N7sVWDaNFcZ5BPwOmEgCgfU8c6v+Ri2F9C4FxF9OEJG+dELFAbyrCxPh9f5cjKNTIWdWsgJpbIy
 eS0G9BQlqzpoBSNGR2XeZZUjUVBhoaoh4U8IKXlM8PPaxljqTFafEx2XTKiA5ZR2+xfXb93fztd
 b/RKh7U8TTYPYSloxEJrLBHTAt1dnJwyQPSnsTVtiR5DyMR+1rN531hOX8Ih3vrCNozRma2e3I0
 qP5CDoEEEKtdEAKBK7A+2agj+/xyBuZbHGD/g3Df/DwmHkZoGKuOUBV4dqnA6g7xBAkAnjHNSo5
 aI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a u8 flags member. It takes one byte of the two-byte hole after
mode, so struct ctl_table stays the same size. Even though we are adding
it to house the overlay flags for the ctl_table_tmpl template, it can be
used as a general way to modify the registration and read/write
operation of the ctl path.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/proc/proc_sysctl.c  | 1 +
 include/linux/sysctl.h | 8 ++++++++
 2 files changed, 9 insertions(+)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index 6c0859c6656356f39010e9d47debc0487b751a32..1c5ccb29707d83bacad06198c0dcab39c8b7b347 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -1343,6 +1343,7 @@ static struct ctl_dir *sysctl_mkdir_p(struct ctl_dir *dir, const char *path)
  * data     - a pointer to data for use by proc_handler
  * maxlen   - the maximum size in bytes of the data
  * mode     - the file permissions for the /proc/sys file
+ * flags    - Used in registration and write/read ops
  * type     - Defines the target type (described in struct definition)
  * proc_handler - the text handler routine (described below)
  *
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 4faa3bc189e7afbc270f4ba14b04b32a3f2d1413..3654fd31e3cc4f9217ae61b0bb4d6f4c677ea237 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -22,6 +22,7 @@
 #ifndef _LINUX_SYSCTL_H
 #define _LINUX_SYSCTL_H
 
+#include <linux/bits.h>
 #include <linux/build_bug.h>
 #include <linux/list.h>
 #include <linux/rcupdate.h>
@@ -219,12 +220,19 @@ static inline void *proc_sys_poll_event(struct ctl_table_poll *poll)
 #define DEFINE_CTL_TABLE_POLL(name)					\
 	struct ctl_table_poll name = __CTL_TABLE_POLL_INITIALIZER(name)
 
+/* Overlay types. Describes what is overlain when registering a template */
+#define SYSCTL_OVERLAY_DATA	BIT(0)
+#define SYSCTL_OVERLAY_EXTRA1	BIT(1)
+#define SYSCTL_OVERLAY_EXTRA2	BIT(2)
+#define SYSCTL_OVERLAY_MODE	BIT(3)
+
 /* A sysctl table is an array of struct ctl_table: */
 struct ctl_table {
 	const char *procname;		/* Text ID for /proc/sys */
 	void *data;
 	int maxlen;
 	umode_t mode;
+	u8 flags;			/* Used in registration and write/read ops */
 	proc_handler *proc_handler;	/* Callback for text formatting */
 	struct ctl_table_poll *poll;
 	void *extra1;

-- 
2.50.1

