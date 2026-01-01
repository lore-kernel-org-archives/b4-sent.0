From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 01 Jan 2026 13:57:12 +0100
Subject: [PATCH v2 8/9] sysctl: Rename proc_doulongvec_minmax_conv to
 proc_doulongvec_conv
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-jag-dovec_consolidate-v2-8-ff918f753ba9@kernel.org>
References: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
In-Reply-To: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3589;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=MzMUFtw28DFdEAcmgt575DTHAbUX+7Aak8PJgw2U3n4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlWby6lDubJMgEskL1wDLPHDk5KSnhJZgPc4
 vSgLbx0hQ4/34kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpVm8uAAoJELqXzVK3
 lkFPxk4L/1bSJ0ctDiLoni3Tsfm2wdh+HwAQGuPZl6Gizt2Il9DMUGAfeQtyCrB9RhRhvJ4z1Ao
 7WCoPBjFgxrkZrbU6rzIvE5k1Q+zza5bc4WHur6NeJc592IFEwOhU1U2D6hl/cp/ayqR358hN5P
 aCA915kXSEg37URh+V2XDb8t+VDFy5m2GMrcS2IBd2atxoDz9tC1BQQuc/x7anXdVBcHqvSC7ib
 UsweMJ3EDcO7sA36ZCCzDxuMtd90GgNZSw48PHh56mtHFTsbw7NR5jmjtsvJvRJNpLL1HTW5NJp
 lpZf/5UUF9J2smMgdZi2MsOfjPETxOZdg/WTZOMiiYrizH/klPTZMkkkYErf9PaOe5Xc2+volRC
 rkUg+F2N9GCZKVThtLfPmMzYChFgTzSRG4NPgINQnmsfYUYSQq3IwyForqZBCs/iOkIKWVu4dCN
 +Rc/z5lCErQ/69oO/W+Z1JGsKow6dtquAOBfNORkr3I3GgUX7H8xJw0+jFziYxT/IGEmv980Wr8
 Eo=
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
index b90924944ad52bcd3347cf5ca7c87ac9455eb70d..09a5b2d86684cd09cbd6e9f074ecdb71ea9bf218 100644
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
@@ -1241,7 +1241,7 @@ int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 	return -ENOSYS;
 }
 
-int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
+int proc_doulongvec_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
 				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
 					    int dir, const struct ctl_table *table))
diff --git a/kernel/time/jiffies.c b/kernel/time/jiffies.c
index 57ed5f363f94bd566aa53c061f20d3f4f2a05944..38a654e79b731956748c5ff9b476fb2adea58d7b 100644
--- a/kernel/time/jiffies.c
+++ b/kernel/time/jiffies.c
@@ -337,8 +337,8 @@ int proc_dointvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
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

