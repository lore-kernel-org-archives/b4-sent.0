From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 16 Oct 2025 14:57:51 +0200
Subject: [PATCH v2 05/11] sysctl: Discriminate between kernel and user
 converter params
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-jag-sysctl_conv-v2-5-a2f16529acc4@kernel.org>
References: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
In-Reply-To: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=10487;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=caF6LtqiOd2vBnpLGcm75cb9MaprTYO9NBhODSG8Pjs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjw6+Xo/DWkTqf4p34t9NR3oKE+NpWRETSqc
 UU6UJscRCSDqIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8OvlAAoJELqXzVK3
 lkFPovkL/RSNrtB9ZOKCTVD1Vpo75QuIt+V9KUxHxs87zneamA3MXSkBLylGYPBqt5/4IYwdeYk
 kpWaXHkLZKkOi4PJ+DNtLFIrFMg9QQ3lcAP53QGbrkBSRil7lWJdYaTUq7uT5n7Xl0iSi7wMopk
 Sd57rl5HqYPFOHRBEu1H6QBGVbvq2SftGyFDnx/rvrHDz7CuXRMvC4pe6zZcwvfw1HKCL1FlZN1
 5QqJOk1Zf5ePyvRTLUFoA+TQoo1zDO7OKTH7G0V9rBo/iQX0y9Ex54CmiXE+zT5f/poT7Leyjij
 iX7ZrRTQg9c/WtqJfp9o1DwsjeQDT3XycABlIlHTcNVCowgrGPLdkcUJyGcRsC3uDpNnJeSY088
 nIzjIl8CazdX3/lq2CSjzKV2uIzjUqHOT7IMnPbZNVCgCIp9luLNdxMr3kJm6fUVqGxhru6GsCn
 W3HrdbZrO9qxK8+7X7zwRCGylh+n+dio8wfr0TiMFdtdWV/4o3+ScVPskSoDXP7B8lvSQIWiDp7
 KI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Rename converter parameter to indicate data flow direction: "lvalp" to
"u_ptr" indicating a user space parsed value pointer. "valp" to "k_ptr"
indicating a kernel storage value pointer. This facilitates the
identification of discrepancies between direction (copy to kernel or
copy to user space) and the modified variable. This is a preparation
commit for when the converter functions are exposed to the rest of the
kernel.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 118 ++++++++++++++++++++++++++++----------------------------
 1 file changed, 59 insertions(+), 59 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 69148fe7359994b85c076b7b6750792b2d1c751e..2091d2396c83ac68d621b3d158ce1c490c392c4b 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -368,44 +368,44 @@ static void proc_put_char(void **buf, size_t *size, char c)
 	}
 }
 
-static int do_proc_dointvec_conv(bool *negp, unsigned long *lvalp,
-				 int *valp, int dir,
+static int do_proc_dointvec_conv(bool *negp, unsigned long *u_ptr,
+				 int *k_ptr, int dir,
 				 const struct ctl_table *table)
 {
 	if (SYSCTL_USER_TO_KERN(dir)) {
 		if (*negp) {
-			if (*lvalp > (unsigned long) INT_MAX + 1)
+			if (*u_ptr > (unsigned long) INT_MAX + 1)
 				return -EINVAL;
-			WRITE_ONCE(*valp, -*lvalp);
+			WRITE_ONCE(*k_ptr, -*u_ptr);
 		} else {
-			if (*lvalp > (unsigned long) INT_MAX)
+			if (*u_ptr > (unsigned long) INT_MAX)
 				return -EINVAL;
-			WRITE_ONCE(*valp, *lvalp);
+			WRITE_ONCE(*k_ptr, *u_ptr);
 		}
 	} else {
-		int val = READ_ONCE(*valp);
+		int val = READ_ONCE(*k_ptr);
 		if (val < 0) {
 			*negp = true;
-			*lvalp = -(unsigned long)val;
+			*u_ptr = -(unsigned long)val;
 		} else {
 			*negp = false;
-			*lvalp = (unsigned long)val;
+			*u_ptr = (unsigned long)val;
 		}
 	}
 	return 0;
 }
 
-static int do_proc_douintvec_conv(unsigned long *lvalp,
-				  unsigned int *valp, int dir,
+static int do_proc_douintvec_conv(unsigned long *u_ptr,
+				  unsigned int *k_ptr, int dir,
 				  const struct ctl_table *table)
 {
 	if (SYSCTL_USER_TO_KERN(dir)) {
-		if (*lvalp > UINT_MAX)
+		if (*u_ptr > UINT_MAX)
 			return -EINVAL;
-		WRITE_ONCE(*valp, *lvalp);
+		WRITE_ONCE(*k_ptr, *u_ptr);
 	} else {
-		unsigned int val = READ_ONCE(*valp);
-		*lvalp = (unsigned long)val;
+		unsigned int val = READ_ONCE(*k_ptr);
+		*u_ptr = (unsigned long)val;
 	}
 	return 0;
 }
@@ -415,7 +415,7 @@ static const char proc_wspace_sep[] = { ' ', '\t', '\n' };
 
 static int do_proc_dointvec(const struct ctl_table *table, int dir,
 		  void *buffer, size_t *lenp, loff_t *ppos,
-		  int (*conv)(bool *negp, unsigned long *lvalp, int *valp,
+		  int (*conv)(bool *negp, unsigned long *u_ptr, int *k_ptr,
 			      int dir, const struct ctl_table *table))
 {
 	int *i, vleft, first = 1, err = 0;
@@ -487,8 +487,8 @@ static int do_proc_dointvec(const struct ctl_table *table, int dir,
 
 static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
-			       int (*conv)(unsigned long *lvalp,
-					   unsigned int *valp, int dir,
+			       int (*conv)(unsigned long *u_ptr,
+					   unsigned int *k_ptr, int dir,
 					   const struct ctl_table *table))
 {
 	unsigned long lval;
@@ -540,8 +540,8 @@ static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 
 static int do_proc_douintvec_r(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
-			       int (*conv)(unsigned long *lvalp,
-					   unsigned int *valp, int dir,
+			       int (*conv)(unsigned long *u_ptr,
+					   unsigned int *k_ptr, int dir,
 					   const struct ctl_table *table))
 {
 	unsigned long lval;
@@ -570,7 +570,7 @@ static int do_proc_douintvec_r(const struct ctl_table *table, void *buffer,
 
 int do_proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 		      size_t *lenp, loff_t *ppos,
-		      int (*conv)(unsigned long *lvalp, unsigned int *valp,
+		      int (*conv)(unsigned long *u_ptr, unsigned int *k_ptr,
 				  int dir, const struct ctl_table *table))
 {
 	unsigned int vleft;
@@ -679,18 +679,18 @@ int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 				 do_proc_douintvec_conv);
 }
 
-static int do_proc_dointvec_minmax_conv(bool *negp, unsigned long *lvalp,
-					int *valp, int dir,
+static int do_proc_dointvec_minmax_conv(bool *negp, unsigned long *u_ptr,
+					int *k_ptr, int dir,
 					const struct ctl_table *table)
 {
 	int tmp, ret, *min, *max;
 	/*
-	 * If writing, first do so via a temporary local int so we can
-	 * bounds-check it before touching *valp.
+	 * If writing to a kernel variable, first do so via a temporary
+	 * local int so we can bounds-check it before touching *k_ptr.
 	 */
-	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : valp;
+	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
 
-	ret = do_proc_dointvec_conv(negp, lvalp, ip, dir, table);
+	ret = do_proc_dointvec_conv(negp, u_ptr, ip, dir, table);
 	if (ret)
 		return ret;
 
@@ -699,7 +699,7 @@ static int do_proc_dointvec_minmax_conv(bool *negp, unsigned long *lvalp,
 		max = (int *) table->extra2;
 		if ((min && *min > tmp) || (max && *max < tmp))
 			return -EINVAL;
-		WRITE_ONCE(*valp, tmp);
+		WRITE_ONCE(*k_ptr, tmp);
 	}
 
 	return 0;
@@ -729,16 +729,16 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 				do_proc_dointvec_minmax_conv);
 }
 
-static int do_proc_douintvec_minmax_conv(unsigned long *lvalp,
-					 unsigned int *valp, int dir,
+static int do_proc_douintvec_minmax_conv(unsigned long *u_ptr,
+					 unsigned int *k_ptr, int dir,
 					 const struct ctl_table *table)
 {
 	int ret;
 	unsigned int tmp, *min, *max;
 	/* When writing to the kernel use a temp local uint for bounds-checking */
-	unsigned int *up = SYSCTL_USER_TO_KERN(dir) ? &tmp : valp;
+	unsigned int *up = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
 
-	ret = do_proc_douintvec_conv(lvalp, up, dir, table);
+	ret = do_proc_douintvec_conv(u_ptr, up, dir, table);
 	if (ret)
 		return ret;
 
@@ -748,7 +748,7 @@ static int do_proc_douintvec_minmax_conv(unsigned long *lvalp,
 		if ((min && *min > tmp) || (max && *max < tmp))
 			return -ERANGE;
 
-		WRITE_ONCE(*valp, tmp);
+		WRITE_ONCE(*k_ptr, tmp);
 	}
 
 	return 0;
@@ -953,19 +953,19 @@ int proc_doulongvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 }
 
 
-static int do_proc_dointvec_jiffies_conv(bool *negp, unsigned long *lvalp,
-					 int *valp, int dir,
+static int do_proc_dointvec_jiffies_conv(bool *negp, unsigned long *u_ptr,
+					 int *k_ptr, int dir,
 					 const struct ctl_table *table)
 {
 	if (SYSCTL_USER_TO_KERN(dir)) {
-		if (*lvalp > INT_MAX / HZ)
+		if (*u_ptr > INT_MAX / HZ)
 			return 1;
 		if (*negp)
-			WRITE_ONCE(*valp, -*lvalp * HZ);
+			WRITE_ONCE(*k_ptr, -*u_ptr * HZ);
 		else
-			WRITE_ONCE(*valp, *lvalp * HZ);
+			WRITE_ONCE(*k_ptr, *u_ptr * HZ);
 	} else {
-		int val = READ_ONCE(*valp);
+		int val = READ_ONCE(*k_ptr);
 		unsigned long lval;
 		if (val < 0) {
 			*negp = true;
@@ -974,21 +974,21 @@ static int do_proc_dointvec_jiffies_conv(bool *negp, unsigned long *lvalp,
 			*negp = false;
 			lval = (unsigned long)val;
 		}
-		*lvalp = lval / HZ;
+		*u_ptr = lval / HZ;
 	}
 	return 0;
 }
 
-static int do_proc_dointvec_userhz_jiffies_conv(bool *negp, unsigned long *lvalp,
-						int *valp, int dir,
+static int do_proc_dointvec_userhz_jiffies_conv(bool *negp, unsigned long *u_ptr,
+						int *k_ptr, int dir,
 						const struct ctl_table *table)
 {
 	if (SYSCTL_USER_TO_KERN(dir)) {
-		if (USER_HZ < HZ && *lvalp > (LONG_MAX / HZ) * USER_HZ)
+		if (USER_HZ < HZ && (LONG_MAX / HZ) * USER_HZ < *u_ptr)
 			return 1;
-		*valp = clock_t_to_jiffies(*negp ? -*lvalp : *lvalp);
+		*k_ptr = clock_t_to_jiffies(*negp ? -*u_ptr : *u_ptr);
 	} else {
-		int val = *valp;
+		int val = *k_ptr;
 		unsigned long lval;
 		if (val < 0) {
 			*negp = true;
@@ -997,23 +997,23 @@ static int do_proc_dointvec_userhz_jiffies_conv(bool *negp, unsigned long *lvalp
 			*negp = false;
 			lval = (unsigned long)val;
 		}
-		*lvalp = jiffies_to_clock_t(lval);
+		*u_ptr = jiffies_to_clock_t(lval);
 	}
 	return 0;
 }
 
-static int do_proc_dointvec_ms_jiffies_conv(bool *negp, unsigned long *lvalp,
-					    int *valp, int dir,
+static int do_proc_dointvec_ms_jiffies_conv(bool *negp, unsigned long *u_ptr,
+					    int *k_ptr, int dir,
 					    const struct ctl_table *table)
 {
 	if (SYSCTL_USER_TO_KERN(dir)) {
-		unsigned long jif = msecs_to_jiffies(*negp ? -*lvalp : *lvalp);
+		unsigned long jif = msecs_to_jiffies(*negp ? -*u_ptr : *u_ptr);
 
 		if (jif > INT_MAX)
 			return 1;
-		WRITE_ONCE(*valp, (int)jif);
+		WRITE_ONCE(*k_ptr, (int)jif);
 	} else {
-		int val = READ_ONCE(*valp);
+		int val = READ_ONCE(*k_ptr);
 		unsigned long lval;
 		if (val < 0) {
 			*negp = true;
@@ -1022,23 +1022,23 @@ static int do_proc_dointvec_ms_jiffies_conv(bool *negp, unsigned long *lvalp,
 			*negp = false;
 			lval = (unsigned long)val;
 		}
-		*lvalp = jiffies_to_msecs(lval);
+		*u_ptr = jiffies_to_msecs(lval);
 	}
 	return 0;
 }
 
-static int do_proc_dointvec_ms_jiffies_minmax_conv(bool *negp, unsigned long *lvalp,
-						int *valp, int dir,
+static int do_proc_dointvec_ms_jiffies_minmax_conv(bool *negp, unsigned long *u_ptr,
+						int *k_ptr, int dir,
 						const struct ctl_table *table)
 {
 	int tmp, ret, *min, *max;
 	/*
-	 * If writing, first do so via a temporary local int so we can
-	 * bounds-check it before touching *valp.
+	 * If writing to a kernel var, first do so via a temporary local
+	 * int so we can bounds-check it before touching *k_ptr.
 	 */
-	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : valp;
+	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
 
-	ret = do_proc_dointvec_ms_jiffies_conv(negp, lvalp, ip, dir, table);
+	ret = do_proc_dointvec_ms_jiffies_conv(negp, u_ptr, ip, dir, table);
 	if (ret)
 		return ret;
 
@@ -1047,7 +1047,7 @@ static int do_proc_dointvec_ms_jiffies_minmax_conv(bool *negp, unsigned long *lv
 		max = (int *) table->extra2;
 		if ((min && *min > tmp) || (max && *max < tmp))
 			return -EINVAL;
-		*valp = tmp;
+		*k_ptr = tmp;
 	}
 	return 0;
 }

-- 
2.50.1

