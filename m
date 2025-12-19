From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 19 Dec 2025 13:15:59 +0100
Subject: [PATCH 8/9] sysctl: Rename proc_doulongvec_minmax_conv to
 proc_doulongvec_conv
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251219-jag-dovec_consolidate-v1-8-1413b92c6040@kernel.org>
References: <20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org>
In-Reply-To: <20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3589;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=xCZl7r2DiBYglyBmPVRMcIhculDAeVzFm9aK8ZXJIjc=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlFQgi96kPd13ciGcp88pvhu/VkjsU3FXBtp
 Mxa5v9E49/9iIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpRUIIAAoJELqXzVK3
 lkFPaMgMAI+NdzeKR6VUSNJVgXooT5Sp5zfgjmaasI82neNWyyQl1G6rfXaVC8WKlKxFj5BNOFG
 BZMx6JxaIKt7k2Pz4qJUVCf2Cdgml/fAdJrd8XiDqyvRgjse/HgmS2GlR87xfkM9SIKq7Jqb+mz
 XzIw+ng+7uvOrJk2L9bH7wrGXIpEK2AtKgGpyNbSjxNaWijxUb2z/kPaR81FSqTSEBzK+i37smf
 qZQuSKx2H00uTLj9i3NaMXu8jL7nK5MZ1sJBTpuYE82nKtVOHPzEMn24KOhOotyMRMDUZ+1TR16
 g85keKU9nQ1HSbdAukpqor8NERV5wrEIi0gGLl+4JJD43qufT/W9yaNiao+Yk4XrB67AyiFo3Ae
 mdOQDmRDLVmoju+07JXMaFayTgCX2EjDKAxZ0krTEuuWh87YLbnS3OQ4bDD0eWvg4xSuScg9YM3
 Nla2p1QFHpnFIvwLfUS3OA9C8ktNdZoHL5qbO5K3e0xbWufS56ESGPS+ORC3Fm9EjHvV1ogp4Z6
 5c=
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
index aecb46bdf4cafc134f83f2014e89a209efc8c10d..3fa59ef77f931c2753584ed03006f3ff9f5a1d0e 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -959,7 +959,7 @@ static int do_proc_ulong_conv(bool *negp, ulong *u_ptr, ulong *k_ptr, int dir,
 }
 
 /**
- * proc_doulongvec_minmax_conv - read a vector of unsigned longs with a custom converter
+ * proc_doulongvec_conv - read a vector of unsigned longs with a custom converter
  *
  * @table: the sysctl table
  * @dir: %TRUE if this is a write to the sysctl file
@@ -974,7 +974,7 @@ static int do_proc_ulong_conv(bool *negp, ulong *u_ptr, ulong *k_ptr, int dir,
  *
  * Returns: 0 on success
  */
-int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
+int proc_doulongvec_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
 				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
 					    int dir, const struct ctl_table *table))
@@ -1239,7 +1239,7 @@ int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
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

