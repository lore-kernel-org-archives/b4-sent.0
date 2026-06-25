From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 25 Jun 2026 22:38:20 +0200
Subject: [PATCH v3 08/10] sysctl: Rename proc_doulongvec_minmax_conv to
 proc_doulongvec_conv
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-jag-dovec_consolidate-v3-8-176ee192bcaf@kernel.org>
References: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
In-Reply-To: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3589;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=kyXLFNHGUnWAevIV1Ogp3P6AOQHOMxfj/cTapCcKySk=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGo9keNCVNi3a5N05ESIgn3HDumfkErZIr0Hj
 Saf+cUWSgrc6YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqPZHjAAoJELqXzVK3
 lkFP6iwL/2yMdS/6M3QZwgqc9fAmLHGGniuVrkyOA29f42oIPNc5lXJ4O42gv3sb4IUJLpzAIKT
 G9nqH7iOUYshqYdd7bRebesmMaY0GY/dESw7GBr3pI2CCkH/ZDBV7yoLw59CZXdJvO9QVSdZ7uk
 vQQEB7sKPzyFzWsmZw7cWEBWCQXFuJuIpYX8JwQCW8eJoUkt11dzLo19ae9QfR1bz+yZh9OJQ4s
 hAlDEOs3GfXgQ7iSSa4TIinPInPRc5KQRSpyjGgc6u0RWSwZDF2EWw9uQ4KD/+/1UWf6Iq2Qp9e
 PP4n9iTTDZo+JqssBAvtrL6fVfcKficFMqLw/4UWiZ81zg+44zUhLL7fL1sernJ5AOi2U2VOz9K
 XzkuOJ1tRjTUuqlvmIqWPHQFcUg3IPakVtCBfy4MTJb34ko9l+JW/8gUnbv0LM1duLYED+/xQdL
 aG8vxeL0l1Sobqs+E/iQ1zaoH33DxgaAr5s9aWVhI50wVn2ydV+4DSInrlB5X8ahQ7OL8Ia8175
 sE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove "_minmax" from proc_doulongvec_minmax_conv as it does not enforce
min/max limits but serves as a generic converter for unsigned long
vectors. Update function declaration in sysctl.h, definition in
sysctl.c, and caller in jiffies.c accordingly.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h | 8 ++++----
 kernel/sysctl.c        | 6 +++---
 kernel/time/jiffies.c  | 4 ++--
 3 files changed, 9 insertions(+), 9 deletions(-)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index ad268dfd9e79f5540a4a85a9a439819fb3172640..39cf1bf9703fc66a3c9c3360ca081b5590339caa 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -121,10 +121,10 @@ int proc_douintvec_conv(const struct ctl_table *ctl, int dir, void *buf,
 			size_t *lenp, loff_t *ppos,
 			int (*conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
 				    int dir, const struct ctl_table *ctl));
-int proc_doulongvec_minmax_conv(const struct ctl_table *ctl, int dir, void *buf,
-				size_t *lenp, loff_t *ppos,
-				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
-					    int dir, const struct ctl_table *ctl));
+int proc_doulongvec_conv(const struct ctl_table *ctl, int dir, void *buf,
+			 size_t *lenp, loff_t *ppos,
+			 int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
+				     int dir, const struct ctl_table *ctl));
 
 /*
  * bi-directional converter functions
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 3c3508814f5df6727251c83913c256446b7ba41d..cff54c4ee88a36ecc643bff5531c640509cff7f4 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -961,7 +961,7 @@ static int do_proc_ulong_conv(bool *negp, ulong *u_ptr, ulong *k_ptr, int dir,
 }
 
 /**
- * proc_doulongvec_minmax_conv - read a vector of unsigned longs with a custom converter
+ * proc_doulongvec_conv - read a vector of unsigned longs with a custom converter
  *
  * @table: the sysctl table
  * @dir: %TRUE if this is a write to the sysctl file
@@ -976,7 +976,7 @@ static int do_proc_ulong_conv(bool *negp, ulong *u_ptr, ulong *k_ptr, int dir,
  *
  * Returns: 0 on success
  */
-int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
+int proc_doulongvec_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
 				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
 					    int dir, const struct ctl_table *table))
@@ -1257,7 +1257,7 @@ int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 	return -ENOSYS;
 }
 
-int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
+int proc_doulongvec_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
 				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
 					    int dir, const struct ctl_table *table))
diff --git a/kernel/time/jiffies.c b/kernel/time/jiffies.c
index 1e587791fd67f4f87ccfa64302db377f724126a7..416b94cf3ee61316b59150fabfeea4d790ce1f94 100644
--- a/kernel/time/jiffies.c
+++ b/kernel/time/jiffies.c
@@ -334,8 +334,8 @@ int proc_dointvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 int proc_doulongvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 				      void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return proc_doulongvec_minmax_conv(table, dir, buffer, lenp, ppos,
-					   do_proc_ulong_conv_ms_jiffies);
+	return proc_doulongvec_conv(table, dir, buffer, lenp, ppos,
+				    do_proc_ulong_conv_ms_jiffies);
 }
 EXPORT_SYMBOL(proc_doulongvec_ms_jiffies_minmax);
 

-- 
2.50.1

