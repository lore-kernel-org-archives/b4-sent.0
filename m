From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 24 Sep 2026 16:34:10 +0200
Subject: [PATCH RFC 2/4] sysctl: Apply sysctl context when flag is active
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260924-lklm-sysctl-headerctx-template-v1-2-b25e51c66ba7@kernel.org>
References: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
In-Reply-To: <20260924-lklm-sysctl-headerctx-template-v1-0-b25e51c66ba7@kernel.org>
To: Kees Cook <kees@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 =?utf-8?q?Ondrej_Mosn=C3=A1=C4=8Dek?= <omosnacek@gmail.com>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Ryan Roberts <ryan.roberts@arm.com>, Serge Hallyn <serge@hallyn.com>, 
 "Eric W . Biederman" <ebiederm@xmission.com>, 
 Alexey Gladkov <legion@kernel.org>, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2730;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=I5CKmhNtTnWeuzjiQtc94qyADu0YXow+af+CzKqUVMc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGq1NOXd5c0dJfW3SBiNoI1dPmuYeuj9U2c8S
 tTl/ZYcVMuHiokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqtTTlAAoJELqXzVK3
 lkFPQSwL+gMJstW2nqQmHrOX+SDossmZOHPV5GBDoHYK1RjArd8v/8QuPILsP33zPYyzPAE0gLU
 n6L5Sf5b8KIdQpthCdlmtai56LrUWNZY5pkyE56qYUYyZ7OHKX7QzKOqcLbsSonPDmJn+sgJKvR
 pLUAycJiLWnMeogMNJ1flpD9OQ7b4VAWDLM+j8BLI0S/OnKWwnogX4cNr4bG8cdkyLfHlDbMiPV
 wfcJPKIqG0tIWhFjMg3i/Q7s2Y92OxYodwOAyOCjyxgYnJjV7RTi4GAbxuDfy6AE/tZmXfrGE1c
 WTONmfzMTKjikZjVK/VgZpA0vW3PwiBc6n8eeShbWVP8rm5q38Pir9wokG0zhCbpu6aqssKu33/
 9GDnNFtcBAi6dtJTCcuqwUn/zpOBzHHEgYJEW0NVQ7aTlq6F5FWSzeNOw92oil1FESLqPQEVeTv
 7JpxrD9GwJr9CWUsqg6We2T9vSQFRslJZlsoKlbQ+1YVdgItxDLyE8z4+K5RHjtdGhTh7nZe7C8
 Ak=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Whenever CTL_TABLE_F_CTX_DATA is set on the entry, overlay the ->data
entry contained in inst on the entry to be passed to proc_handlers. No
table sets the flags yet, so there is no functional change.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/proc/proc_sysctl.c | 27 ++++++++++++++++++++++++++-
 1 file changed, 26 insertions(+), 1 deletion(-)

diff --git a/fs/proc/proc_sysctl.c b/fs/proc/proc_sysctl.c
index fe32337892f9badc897a29e9176e66790003fb05..1ed9f4e1a17e28c5db1d07356390cbee968cb91f 100644
--- a/fs/proc/proc_sysctl.c
+++ b/fs/proc/proc_sysctl.c
@@ -550,12 +550,31 @@ static struct dentry *proc_sys_lookup(struct inode *dir, struct dentry *dentry,
 	return err;
 }
 
+/* Returns @entry itself when it is not flagged, else a resolved copy in @buf. */
+static const struct ctl_table *sysctl_apply_ctx(struct ctl_table_header *head,
+						const struct ctl_table *entry,
+						struct ctl_table *buf)
+{
+	ptrdiff_t off;
+
+	if (!(entry->flags & CTL_TABLE_F_CTX_DATA))
+		return entry;
+
+	off = (const char *)entry->data - (const char *)head->ctx.tmpl;
+
+	*buf = *entry;
+	buf->data = (char *)head->ctx.inst + off;
+
+	return buf;
+}
+
 static ssize_t proc_sys_call_handler(struct kiocb *iocb, struct iov_iter *iter,
 		int write)
 {
 	struct inode *inode = file_inode(iocb->ki_filp);
 	struct ctl_table_header *head = grab_header(inode);
 	const struct ctl_table *table = PROC_I(inode)->sysctl_entry;
+	struct ctl_table ctx_entry;
 	size_t count = iov_iter_count(iter);
 	char *kbuf;
 	ssize_t error;
@@ -567,6 +586,8 @@ static ssize_t proc_sys_call_handler(struct kiocb *iocb, struct iov_iter *iter,
 	 * At this point we know that the sysctl was not unregistered
 	 * and won't be until we finish.
 	 */
+	table = sysctl_apply_ctx(head, table, &ctx_entry);
+
 	error = -EPERM;
 	if (sysctl_perm(head, table, write ? MAY_WRITE : MAY_READ))
 		goto out;
@@ -797,6 +818,7 @@ static int proc_sys_permission(struct mnt_idmap *idmap,
 	 */
 	struct ctl_table_header *head;
 	const struct ctl_table *table;
+	struct ctl_table ctx_entry;
 	int error;
 
 	/* Executable files are not allowed under /proc/sys/ */
@@ -810,8 +832,11 @@ static int proc_sys_permission(struct mnt_idmap *idmap,
 	table = PROC_I(inode)->sysctl_entry;
 	if (!table) /* global root - r-xr-xr-x */
 		error = mask & MAY_WRITE ? -EACCES : 0;
-	else /* Use the permissions on the sysctl table entry */
+	else {
+		/* ->permissions may inspect the entry, so resolve it first. */
+		table = sysctl_apply_ctx(head, table, &ctx_entry);
 		error = sysctl_perm(head, table, mask & ~MAY_NOT_BLOCK);
+	}
 
 	sysctl_head_finish(head);
 	return error;

-- 
2.50.1

