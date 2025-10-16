From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 16 Oct 2025 14:57:54 +0200
Subject: [PATCH v2 08/11] sysctl: Add optional range checking to
 SYSCTL_INT_CONV_CUSTOM
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-jag-sysctl_conv-v2-8-a2f16529acc4@kernel.org>
References: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
In-Reply-To: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6108;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=WFmYwNqRtEEV71HErtXjnELu0hh+bKYykNpfWVGpcO8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjw6+apDIedVblwlaTEI8ojelRgkHAc7asxX
 2RAFfsLi3oEVIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8OvmAAoJELqXzVK3
 lkFP3hIL/1YA6bZ6sWEABAzd0w8iR1j0DI8ChPn3AQydkeJUsBi9Y7ET9pfipymKMNZ4ny59/bm
 0uwEAnjWsqNq6y1zz0cMMpBTCcB8+0QHHd+pqjKPe4gl1X4LZfF+dlFi9bcBKzUv2FiNplHdiGt
 LpqdJNI/Ty/IC9IpaRX0nAV/qRM86NjeOlmMxcgRwl/De3MSdMGbVO/ixveeAq8zkaJ5ClRsGg5
 AEfBQFF3H4R3MSTe5oOPE42kbNKjZHDkeaTfnpK+8v4RjMCuh1RFFGPA//9lCrVh4cpvac5KrVt
 QTd35zuMPpPUBX8h9UzBGBZo/SeANr1Yp9RtX5zhtYlW8oSAlOUjb2epxlHTVALHjbzbbCBVixa
 Y5VvQRQo1Hi9j6jCqAif/1F5PDgf1cn0AgZRoWhMS/F41oxZ6Pq97/WT4cBrBZ7eLC9BkY599rE
 8hMjO8IlToBaCj0I0MUmtGdc1hn8mKMzTVKgZ1xngX8D422cMIjD2rf7Mp74hBHMomko6Hiz5F5
 PU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Extend the SYSCTL_INT_CONV_CUSTOM macro with a k_ptr_range_check
parameter to conditionally generate range validation code. When enabled,
validation is done against table->extra1 (min) and table->extra2 (max)
bounds before assignment. Add base minmax and ms_jiffies_minmax
converter instances that utilize the range checking functionality.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 106 +++++++++++++++++++++-----------------------------------
 1 file changed, 40 insertions(+), 66 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index e7dc4b79e93ea9ab929ce0465143aed74be444e5..60f7618083516a24530f46f6eabccd108e90c74f 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -402,6 +402,34 @@ int sysctl_kern_to_user_int_conv##name(bool *negp,		\
 	return 0;						\
 }
 
+/**
+ * To range check on a converted value, use a temp k_ptr
+ * When checking range, value should be within (tbl->extra1, tbl->extra2)
+ */
+#define SYSCTL_INT_CONV_CUSTOM(name, user_to_kern, kern_to_user,	\
+			       k_ptr_range_check)			\
+int do_proc_int_conv##name(bool *negp, unsigned long *u_ptr, int *k_ptr,\
+			   int dir, const struct ctl_table *tbl)	\
+{									\
+	if (SYSCTL_KERN_TO_USER(dir))					\
+		return kern_to_user(negp, u_ptr, k_ptr);		\
+									\
+	if (k_ptr_range_check) {					\
+		int tmp_k, ret;						\
+		if (!tbl)						\
+			return -EINVAL;					\
+		ret = user_to_kern(negp, u_ptr, &tmp_k);		\
+		if (ret)						\
+			return ret;					\
+		if ((tbl->extra1 && *(int *)tbl->extra1 > tmp_k) ||	\
+		    (tbl->extra2 && *(int *)tbl->extra2 < tmp_k))	\
+			return -EINVAL;					\
+		WRITE_ONCE(*k_ptr, tmp_k);				\
+	} else								\
+		return user_to_kern(negp, u_ptr, k_ptr);		\
+	return 0;							\
+}
+
 #define SYSCTL_CONV_IDENTITY(val) val
 #define SYSCTL_CONV_MULT_HZ(val) ((val) * HZ)
 #define SYSCTL_CONV_DIV_HZ(val) ((val) / HZ)
@@ -418,24 +446,21 @@ static SYSCTL_KERN_TO_USER_INT_CONV(_userhz, jiffies_to_clock_t)
 static SYSCTL_USER_TO_KERN_INT_CONV(_ms, msecs_to_jiffies)
 static SYSCTL_KERN_TO_USER_INT_CONV(_ms, jiffies_to_msecs)
 
-#define SYSCTL_INT_CONV_CUSTOM(name, user_to_kern, kern_to_user)	\
-int do_proc_int_conv##name(bool *negp, unsigned long *u_ptr, int *k_ptr,\
-			   int dir, const struct ctl_table *table)	\
-{									\
-	if (SYSCTL_USER_TO_KERN(dir))					\
-		return user_to_kern(negp, u_ptr, k_ptr);		\
-	return kern_to_user(negp, u_ptr, k_ptr);			\
-}
-
 static SYSCTL_INT_CONV_CUSTOM(, sysctl_user_to_kern_int_conv,
-			      sysctl_kern_to_user_int_conv)
+			      sysctl_kern_to_user_int_conv, false)
 static SYSCTL_INT_CONV_CUSTOM(_jiffies, sysctl_user_to_kern_int_conv_hz,
-			      sysctl_kern_to_user_int_conv_hz)
+			      sysctl_kern_to_user_int_conv_hz, false)
 static SYSCTL_INT_CONV_CUSTOM(_userhz_jiffies,
 			      sysctl_user_to_kern_int_conv_userhz,
-			      sysctl_kern_to_user_int_conv_userhz)
+			      sysctl_kern_to_user_int_conv_userhz, false)
 static SYSCTL_INT_CONV_CUSTOM(_ms_jiffies, sysctl_user_to_kern_int_conv_ms,
-			      sysctl_kern_to_user_int_conv_ms)
+			      sysctl_kern_to_user_int_conv_ms, false)
+
+static SYSCTL_INT_CONV_CUSTOM(_minmax, sysctl_user_to_kern_int_conv,
+			      sysctl_kern_to_user_int_conv, true)
+static SYSCTL_INT_CONV_CUSTOM(_ms_jiffies_minmax,
+			      sysctl_user_to_kern_int_conv_ms,
+			      sysctl_kern_to_user_int_conv_ms, true)
 
 static int do_proc_douintvec_conv(unsigned long *u_ptr,
 				  unsigned int *k_ptr, int dir,
@@ -721,32 +746,6 @@ int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 				 do_proc_douintvec_conv);
 }
 
-static int do_proc_dointvec_minmax_conv(bool *negp, unsigned long *u_ptr,
-					int *k_ptr, int dir,
-					const struct ctl_table *table)
-{
-	int tmp, ret, *min, *max;
-	/*
-	 * If writing to a kernel variable, first do so via a temporary
-	 * local int so we can bounds-check it before touching *k_ptr.
-	 */
-	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
-
-	ret = do_proc_int_conv(negp, u_ptr, ip, dir, table);
-	if (ret)
-		return ret;
-
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		min = (int *) table->extra1;
-		max = (int *) table->extra2;
-		if ((min && *min > tmp) || (max && *max < tmp))
-			return -EINVAL;
-		WRITE_ONCE(*k_ptr, tmp);
-	}
-
-	return 0;
-}
-
 /**
  * proc_dointvec_minmax - read a vector of integers with min/max values
  * @table: the sysctl table
@@ -768,7 +767,7 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 		  void *buffer, size_t *lenp, loff_t *ppos)
 {
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos,
-				do_proc_dointvec_minmax_conv);
+				do_proc_int_conv_minmax);
 }
 
 static int do_proc_douintvec_minmax_conv(unsigned long *u_ptr,
@@ -994,31 +993,6 @@ int proc_doulongvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 					 lenp, ppos, HZ, 1000l);
 }
 
-static int do_proc_dointvec_ms_jiffies_minmax_conv(bool *negp, unsigned long *u_ptr,
-						int *k_ptr, int dir,
-						const struct ctl_table *table)
-{
-	int tmp, ret, *min, *max;
-	/*
-	 * If writing to a kernel var, first do so via a temporary local
-	 * int so we can bounds-check it before touching *k_ptr.
-	 */
-	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
-
-	ret = do_proc_int_conv_ms_jiffies(negp, u_ptr, ip, dir, table);
-	if (ret)
-		return ret;
-
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		min = (int *) table->extra1;
-		max = (int *) table->extra2;
-		if ((min && *min > tmp) || (max && *max < tmp))
-			return -EINVAL;
-		*k_ptr = tmp;
-	}
-	return 0;
-}
-
 /**
  * proc_dointvec_jiffies - read a vector of integers as seconds
  * @table: the sysctl table
@@ -1045,7 +1019,7 @@ int proc_dointvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 			  void *buffer, size_t *lenp, loff_t *ppos)
 {
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos,
-			do_proc_dointvec_ms_jiffies_minmax_conv);
+			do_proc_int_conv_ms_jiffies_minmax);
 }
 
 /**

-- 
2.50.1

