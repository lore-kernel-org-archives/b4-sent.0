From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 25 Jun 2026 22:38:15 +0200
Subject: [PATCH v3 03/10] sysctl: Generate do_proc_doulongvec_minmax with
 do_proc_dotypevec macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-jag-dovec_consolidate-v3-3-176ee192bcaf@kernel.org>
References: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
In-Reply-To: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=11977;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Y1KbSB54EWU+RhJEIOm5K08f/4GZEHRazL8iINjVzvs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGo9keAnzstCfSxsEfz7udGt00snmIviYVSB8
 MVTr8mslz+nEokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqPZHgAAoJELqXzVK3
 lkFPNwoL/03YSmmVQTnHd69c+DPOewUz2pqIl2kYudPQUcJn5yHVql2xzvVRveI5gO695MpGe7m
 QuxpTdp626rOiop9QKTgdAx2MmmHm4nAdXW5QZg20Wqsmr8cV3EZ264xkP1bMXeeRQAIzd5B1Sj
 YvVpPRZM1JXv26a04e6iHqfyqTaQpr5UOpRWBA4C3XRO94queeuln90FeCH9I7Kdl7Rrd0SEA0s
 AfyxMlOMvCawmC8OG17dwkpL9qI7gNyOgv5IaCeX4pC769reNrSlVl4ep1QQrqfzmWAiBC/b0W0
 3u3V57lvm4HLVzRItZFlWu2LBPvu+ZZdKV2QfLyxqBLDL3yCJYAz5KUw8DbO7rGwyC7ti2/VYWW
 pzrKpg+PNVyvYrNJXuYPZ6w25hKaO30eHNUVNr2zLnVCmUnX2Hui3daVMUZIxTeVZdnk9Ga9vmP
 3qFy5e7PEOt0WTRwwAa64leD8nYUiUeWv4bO34e/hP0HyOsl8FXT13VI8YO007YZ4n7swvymtn8
 U4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The existing do_proc_doulongvec_minmax conversions (based on conv{mul,div})
are replaced with a call to a converter callback that is passed by the
caller.

Replace the values (HZ, 1000l) passed to proc_doulongvec_minmax_conv in
jiffies.c with a new callback containing millisecond to jiffie
conversion (do_proc_ulong_conv_ms_jiffies). This effectively changes the
simple calculation based on HZ and 1000l to a more robust conversion
based on  {_,}_msecs_to_jiffies.

Change specifics
================
* sysctl.h API
 - Implement new ulong uni & bi-directional converters (proc_ulong_*);
   export them so they can be used in proc_doulongvec_ms_jiffies_minmax
   (jiffies.c).
 - Replace two arguments (conv{mul,div}) in proc_doulongvec_minmax_conv
   with a general converter callback function that will be forwarded to
   do_proc_doulongvec.

* do_proc_doulongvec
 - Replace the hardcoded uni-directional converters with a call to the
   call back converter function
 - Generate do_proc_doulongvec with do_proc_dotypevec macro
 - Rename do_proc_doulongvec_minmax to do_proc_doulongvec

* jiffies
 - Create uni and bi-directional converters for milliseconds to jiffies
   (sysctl_{u2k,k2u}_ulong_conv_ms, do_proc_ulong_conv_ms_jiffies)
 - Pass the new bi-directional converter to proc_doulongvec_minmax_conv.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h |  11 ++-
 kernel/sysctl.c        | 182 ++++++++++++++++++++++++++++++-------------------
 kernel/time/jiffies.c  |  26 ++++++-
 3 files changed, 148 insertions(+), 71 deletions(-)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 2886fbceb5d635fc7e0282c7467dcf82708919fe..5c8c17f98513983a459c54eae99d1cc8bd63b011 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -117,11 +117,20 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int write, void *buffer,
 int proc_doulongvec_minmax(const struct ctl_table *, int, void *, size_t *, loff_t *);
 int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
-				unsigned long convmul, unsigned long convdiv);
+				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
+					    int dir, const struct ctl_table *table));
 int proc_do_large_bitmap(const struct ctl_table *, int, void *, size_t *, loff_t *);
 int proc_do_static_key(const struct ctl_table *table, int write, void *buffer,
 		size_t *lenp, loff_t *ppos);
 
+int proc_ulong_u2k_conv_uop(const ulong *u_ptr, ulong *k_ptr,
+			    ulong (*u_ptr_op)(const ulong));
+int proc_ulong_k2u_conv_kop(ulong *u_ptr, const ulong *k_ptr,
+			    ulong (*k_ptr_op)(const ulong));
+int proc_ulong_conv(ulong *u_ptr, ulong *k_ptr, int dir,
+		    const struct ctl_table *tbl, bool k_ptr_range_check,
+		    int (*user_to_kern)(const ulong *u_ptr, ulong *k_ptr),
+		    int (*kern_to_user)(ulong *u_ptr, const ulong *k_ptr));
 /*
  * Register a set of sysctl names by calling register_sysctl
  * with an initialised array of struct ctl_table's.
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index da91fc037c66d70ed6923f1e6de045580359d04f..3208633992557c3a6c3e8effcdfa2cb0781e45ba 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -650,6 +650,7 @@ out: \
 }
 
 do_proc_dotypevec(int)
+do_proc_dotypevec(ulong)
 
 static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
@@ -971,87 +972,128 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int dir,
 }
 EXPORT_SYMBOL_GPL(proc_dou8vec_minmax);
 
-static int do_proc_doulongvec_minmax(const struct ctl_table *table, int dir,
-				     void *buffer, size_t *lenp, loff_t *ppos,
-				     unsigned long convmul,
-				     unsigned long convdiv)
+/**
+ * proc_ulong_conv - Change user or kernel pointer based on direction
+ *
+ * @u_ptr: pointer to user variable
+ * @k_ptr: pointer to kernel variable
+ * @dir: %TRUE if this is a write to the sysctl file
+ * @tbl: the sysctl table
+ * @k_ptr_range_check: Check range for k_ptr when %TRUE
+ * @user_to_kern: Callback used to assign value from user to kernel var
+ * @kern_to_user: Callback used to assign value from kernel to user var
+ *
+ * When direction is kernel to user, then the u_ptr is modified.
+ * When direction is user to kernel, then the k_ptr is modified.
+ *
+ * Returns: 0 on success
+ */
+int proc_ulong_conv(ulong *u_ptr, ulong *k_ptr, int dir,
+		    const struct ctl_table *tbl, bool k_ptr_range_check,
+		    int (*user_to_kern)(const ulong *u_ptr, ulong *k_ptr),
+		    int (*kern_to_user)(ulong *u_ptr, const ulong *k_ptr))
 {
-	unsigned long *i, *min, *max;
-	int vleft, first = 1, err = 0;
-	size_t left;
-	char *p;
+	if (SYSCTL_KERN_TO_USER(dir))
+		return kern_to_user(u_ptr, k_ptr);
 
-	if (!table->data || !table->maxlen || !*lenp ||
-	    (*ppos && SYSCTL_KERN_TO_USER(dir))) {
-		*lenp = 0;
-		return 0;
-	}
+	if (k_ptr_range_check) {
+		ulong tmp_k;
+		int ret;
 
-	i = table->data;
-	min = table->extra1;
-	max = table->extra2;
-	vleft = table->maxlen / sizeof(unsigned long);
-	left = *lenp;
-
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		if (proc_first_pos_non_zero_ignore(ppos, table))
-			goto out;
-
-		if (left > PAGE_SIZE - 1)
-			left = PAGE_SIZE - 1;
-		p = buffer;
-	}
+		if (!tbl)
+			return -EINVAL;
+		ret = user_to_kern(u_ptr, &tmp_k);
+		if (ret)
+			return ret;
+		if ((tbl->extra1 && *(ulong *)tbl->extra1 > tmp_k) ||
+		    (tbl->extra2 && *(ulong *)tbl->extra2 < tmp_k))
+			return -ERANGE;
+		WRITE_ONCE(*k_ptr, tmp_k);
+	} else
+		return user_to_kern(u_ptr, k_ptr);
+	return 0;
+}
 
-	for (; left && vleft--; i++, first = 0) {
-		unsigned long val;
+/**
+ * proc_ulong_u2k_conv_uop - Assign user value to a kernel pointer
+ *
+ * @u_ptr: pointer to user space variable
+ * @k_ptr: pointer to kernel variable
+ * @u_ptr_op: execute this function before assigning to k_ptr
+ *
+ * Uses WRITE_ONCE to assign value to k_ptr. Executes u_ptr_op if
+ * not NULL.
+ *
+ * returns: 0 on success.
+ */
+int proc_ulong_u2k_conv_uop(const ulong *u_ptr, ulong *k_ptr,
+			    ulong (*u_ptr_op)(const ulong))
+{
+	ulong u = u_ptr_op ? u_ptr_op(*u_ptr) : *u_ptr;
 
-		if (SYSCTL_USER_TO_KERN(dir)) {
-			bool neg;
+	WRITE_ONCE(*k_ptr, u);
+	return 0;
+}
 
-			proc_skip_spaces(&p, &left);
-			if (!left)
-				break;
+static int proc_ulong_u2k_conv(const ulong *u_ptr, ulong *k_ptr)
+{
+	return proc_ulong_u2k_conv_uop(u_ptr, k_ptr, NULL);
+}
 
-			err = proc_get_long(&p, &left, &val, &neg,
-					     proc_wspace_sep,
-					     sizeof(proc_wspace_sep), NULL);
-			if (err || neg) {
-				err = -EINVAL;
-				break;
-			}
+/**
+ * proc_ulong_k2u_conv_kop - Assign kernel value to a user space pointer
+ *
+ * @u_ptr: pointer to user space variable
+ * @k_ptr: pointer to kernel variable
+ * @k_ptr_op: Operation applied to k_ptr before assignment
+ *
+ * Uses READ_ONCE to assign value to u_ptr. Executes k_ptr_op if
+ * not NULL.
+ *
+ * returns: 0 on success.
+ */
+int proc_ulong_k2u_conv_kop(ulong *u_ptr, const ulong *k_ptr,
+			    ulong (*k_ptr_op)(const ulong))
+{
+	ulong val = k_ptr_op ? k_ptr_op(READ_ONCE(*k_ptr)) : READ_ONCE(*k_ptr);
+	*u_ptr = (ulong)val;
+	return 0;
+}
 
-			val = convmul * val / convdiv;
-			if ((min && val < *min) || (max && val > *max)) {
-				err = -EINVAL;
-				break;
-			}
-			WRITE_ONCE(*i, val);
-		} else {
-			val = convdiv * READ_ONCE(*i) / convmul;
-			if (!first)
-				proc_put_char(&buffer, &left, '\t');
-			proc_put_long(&buffer, &left, val, false);
-		}
-	}
+static int proc_ulong_k2u_conv(ulong *u_ptr, const ulong *k_ptr)
+{
+	return proc_ulong_k2u_conv_kop(u_ptr, k_ptr, NULL);
+}
 
-	if (SYSCTL_KERN_TO_USER(dir) && !first && left && !err)
-		proc_put_char(&buffer, &left, '\n');
-	if (SYSCTL_USER_TO_KERN(dir) && !err)
-		proc_skip_spaces(&p, &left);
-	if (SYSCTL_USER_TO_KERN(dir) && first)
-		return err ? : -EINVAL;
-	*lenp -= left;
-out:
-	*ppos += *lenp;
-	return err;
+static int do_proc_ulong_conv(bool *negp, ulong *u_ptr, ulong *k_ptr, int dir,
+			      const struct ctl_table *tbl)
+{
+	return proc_ulong_conv(u_ptr, k_ptr, dir, tbl, true,
+			       proc_ulong_u2k_conv, proc_ulong_k2u_conv);
 }
 
+/**
+ * proc_doulongvec_minmax_conv - read a vector of unsigned longs with a custom converter
+ *
+ * @table: the sysctl table
+ * @dir: %TRUE if this is a write to the sysctl file
+ * @buffer: the user buffer
+ * @lenp: the size of the user buffer
+ * @ppos: file position
+ * @conv: Custom converter call back
+ *
+ * Reads/writes up to table->maxlen/sizeof(unsigned long) unsigned long
+ * values from/to the user buffer, treated as an ASCII string. Negative
+ * strings are not allowed.
+ *
+ * Returns: 0 on success
+ */
 int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
-				unsigned long convmul, unsigned long convdiv)
+				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
+					    int dir, const struct ctl_table *table))
 {
-	return do_proc_doulongvec_minmax(table, dir, buffer, lenp, ppos,
-					 convmul, convdiv);
+	return do_proc_doulongvec(table, dir, buffer, lenp, ppos, conv);
 }
 
 /**
@@ -1073,7 +1115,8 @@ int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
 int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 			   void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return proc_doulongvec_minmax_conv(table, dir, buffer, lenp, ppos, 1l, 1l);
+	return do_proc_doulongvec(table, dir, buffer, lenp, ppos,
+				  do_proc_ulong_conv);
 }
 
 /**
@@ -1328,7 +1371,8 @@ int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 
 int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
 				void *buffer, size_t *lenp, loff_t *ppos,
-				unsigned long convmul, unsigned long convdiv)
+				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
+					    int dir, const struct ctl_table *table))
 {
 	return -ENOSYS;
 }
diff --git a/kernel/time/jiffies.c b/kernel/time/jiffies.c
index 1c954f330dfe781d0274e38225b503c106fb5775..1e587791fd67f4f87ccfa64302db377f724126a7 100644
--- a/kernel/time/jiffies.c
+++ b/kernel/time/jiffies.c
@@ -186,6 +186,24 @@ static int do_proc_int_conv_ms_jiffies_minmax(bool *negp, ulong *u_ptr,
 			     sysctl_u2k_int_conv_ms, sysctl_k2u_int_conv_ms);
 }
 
+static int sysctl_u2k_ulong_conv_ms(const ulong *u_ptr, ulong *k_ptr)
+{
+	return proc_ulong_u2k_conv_uop(u_ptr, k_ptr, sysctl_msecs_to_jiffies);
+}
+
+static int sysctl_k2u_ulong_conv_ms(ulong *u_ptr, const ulong *k_ptr)
+{
+	return proc_ulong_k2u_conv_kop(u_ptr, k_ptr, sysctl_jiffies_to_msecs);
+}
+
+static int do_proc_ulong_conv_ms_jiffies(bool *negp, ulong *u_ptr, ulong *k_ptr,
+					 int dir, const struct ctl_table *tbl)
+{
+	return proc_ulong_conv(u_ptr, k_ptr, dir, tbl, false,
+			       sysctl_u2k_ulong_conv_ms, sysctl_k2u_ulong_conv_ms);
+}
+
+
 #else // CONFIG_PROC_SYSCTL
 static int do_proc_int_conv_jiffies(bool *negp, ulong *u_ptr, int *k_ptr,
 				    int dir, const struct ctl_table *tbl)
@@ -212,6 +230,12 @@ static int do_proc_int_conv_ms_jiffies_minmax(bool *negp, ulong *u_ptr,
 {
 	return -ENOSYS;
 }
+
+static int do_proc_ulong_conv_ms_jiffies(bool *negp, ulong *u_ptr, ulong *k_ptr,
+					 int dir, const struct ctl_table *tbl)
+{
+	return -ENOSYS;
+}
 #endif
 
 /**
@@ -311,7 +335,7 @@ int proc_doulongvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 				      void *buffer, size_t *lenp, loff_t *ppos)
 {
 	return proc_doulongvec_minmax_conv(table, dir, buffer, lenp, ppos,
-					   HZ, 1000l);
+					   do_proc_ulong_conv_ms_jiffies);
 }
 EXPORT_SYMBOL(proc_doulongvec_ms_jiffies_minmax);
 

-- 
2.50.1

