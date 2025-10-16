From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 16 Oct 2025 14:57:53 +0200
Subject: [PATCH v2 07/11] sysctl: Create integer converters with one macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-jag-sysctl_conv-v2-7-a2f16529acc4@kernel.org>
References: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
In-Reply-To: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5636;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=KD+2NkFaHlPghXWKYGaZ79Eguljp8JHhe47tIb8ZfcQ=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjw6+Y2Ed26Q6lscjWsOC3opmYd4U/URhoyW
 HWQZlvWQLJPqYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8OvmAAoJELqXzVK3
 lkFPsqUL/3sTrTN7+xIsoOWEvA+Xzy1vgBK2MTqx7rd98HL2U26kXul6QCrKv6Fq6wmZhvio4ZQ
 jJ/3Iyg5ZrkS5HdvApzPiu5JmNlkeREfNVLe2gvxxFNUVwKmuDq/uepEABEgpYZJ0EHPpUKXhiL
 BsE6xSqbZAn2RUbHmwF525d+IfeWo1BRfGY88O41glcqRGOhE3KGw2jTTVP+oeBRDmte07Rx0GS
 xQBTHSrIdMvzQkhe7/UwWqiotCw2sFppeU2wQCv4/1dAZtDUK0WDrk3RAp60wYaCsCMND93y2KB
 hkhUpfW3STj5NZrlIfghQHMdbSqSOBrOfC2J/CtBecXcGePRkynVXU/ggGXZaZUbNanqvw1iFBN
 MVQv/l7NmvLsJWVfXUVyCVzubrQfDB6tDVmMlWysjujD5v7R2L1EzfSBpTcNrZpV/8UX14m1tcZ
 +WPV/c/egiQQH0bIKvqZylg1fhpms1foZZ1s0uqw/4bWUmgelac+Ddb19PpfC9v9QGtjZZmU5o5
 FI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

New SYSCTL_INT_CONV_CUSTOM macro creates "bi-directional" converters
from a user-to-kernel and a kernel-to-user functions. Replace integer
versions of do_proc_*_conv functions with the ones from the new macro.
Rename "_dointvec_" to just "_int_" as these converters are not applied
to vectors and the "do" is already in the name.

Move the USER_HZ validation directly into proc_dointvec_userhz_jiffies()

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 72 ++++++++++++++++++++-------------------------------------
 1 file changed, 25 insertions(+), 47 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index f47bb8af33fb1d2d1a2a7c13d7ca093af82c6400..e7dc4b79e93ea9ab929ce0465143aed74be444e5 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -418,17 +418,25 @@ static SYSCTL_KERN_TO_USER_INT_CONV(_userhz, jiffies_to_clock_t)
 static SYSCTL_USER_TO_KERN_INT_CONV(_ms, msecs_to_jiffies)
 static SYSCTL_KERN_TO_USER_INT_CONV(_ms, jiffies_to_msecs)
 
-static int do_proc_dointvec_conv(bool *negp, unsigned long *u_ptr,
-				 int *k_ptr, int dir,
-				 const struct ctl_table *table)
-{
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		return sysctl_user_to_kern_int_conv(negp, u_ptr, k_ptr);
-	}
-
-	return sysctl_kern_to_user_int_conv(negp, u_ptr, k_ptr);
+#define SYSCTL_INT_CONV_CUSTOM(name, user_to_kern, kern_to_user)	\
+int do_proc_int_conv##name(bool *negp, unsigned long *u_ptr, int *k_ptr,\
+			   int dir, const struct ctl_table *table)	\
+{									\
+	if (SYSCTL_USER_TO_KERN(dir))					\
+		return user_to_kern(negp, u_ptr, k_ptr);		\
+	return kern_to_user(negp, u_ptr, k_ptr);			\
 }
 
+static SYSCTL_INT_CONV_CUSTOM(, sysctl_user_to_kern_int_conv,
+			      sysctl_kern_to_user_int_conv)
+static SYSCTL_INT_CONV_CUSTOM(_jiffies, sysctl_user_to_kern_int_conv_hz,
+			      sysctl_kern_to_user_int_conv_hz)
+static SYSCTL_INT_CONV_CUSTOM(_userhz_jiffies,
+			      sysctl_user_to_kern_int_conv_userhz,
+			      sysctl_kern_to_user_int_conv_userhz)
+static SYSCTL_INT_CONV_CUSTOM(_ms_jiffies, sysctl_user_to_kern_int_conv_ms,
+			      sysctl_kern_to_user_int_conv_ms)
+
 static int do_proc_douintvec_conv(unsigned long *u_ptr,
 				  unsigned int *k_ptr, int dir,
 				  const struct ctl_table *table)
@@ -467,7 +475,7 @@ static int do_proc_dointvec(const struct ctl_table *table, int dir,
 	left = *lenp;
 
 	if (!conv)
-		conv = do_proc_dointvec_conv;
+		conv = do_proc_int_conv;
 
 	if (SYSCTL_USER_TO_KERN(dir)) {
 		if (proc_first_pos_non_zero_ignore(ppos, table))
@@ -724,7 +732,7 @@ static int do_proc_dointvec_minmax_conv(bool *negp, unsigned long *u_ptr,
 	 */
 	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
 
-	ret = do_proc_dointvec_conv(negp, u_ptr, ip, dir, table);
+	ret = do_proc_int_conv(negp, u_ptr, ip, dir, table);
 	if (ret)
 		return ret;
 
@@ -986,38 +994,6 @@ int proc_doulongvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 					 lenp, ppos, HZ, 1000l);
 }
 
-static int do_proc_dointvec_jiffies_conv(bool *negp, unsigned long *u_ptr,
-					 int *k_ptr, int dir,
-					 const struct ctl_table *table)
-{
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		return sysctl_user_to_kern_int_conv_hz(negp, u_ptr, k_ptr);
-	}
-	return sysctl_kern_to_user_int_conv_hz(negp, u_ptr, k_ptr);
-}
-
-static int do_proc_dointvec_userhz_jiffies_conv(bool *negp, unsigned long *u_ptr,
-						int *k_ptr, int dir,
-						const struct ctl_table *table)
-{
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		if (USER_HZ < HZ)
-			return -EINVAL;
-		return sysctl_user_to_kern_int_conv_userhz(negp, u_ptr, k_ptr);
-	}
-	return sysctl_kern_to_user_int_conv_userhz(negp, u_ptr, k_ptr);
-}
-
-static int do_proc_dointvec_ms_jiffies_conv(bool *negp, unsigned long *u_ptr,
-					    int *k_ptr, int dir,
-					    const struct ctl_table *table)
-{
-	if (SYSCTL_USER_TO_KERN(dir)) {
-		return sysctl_user_to_kern_int_conv_ms(negp, u_ptr, k_ptr);
-	}
-	return sysctl_kern_to_user_int_conv_ms(negp, u_ptr, k_ptr);
-}
-
 static int do_proc_dointvec_ms_jiffies_minmax_conv(bool *negp, unsigned long *u_ptr,
 						int *k_ptr, int dir,
 						const struct ctl_table *table)
@@ -1029,7 +1005,7 @@ static int do_proc_dointvec_ms_jiffies_minmax_conv(bool *negp, unsigned long *u_
 	 */
 	int *ip = SYSCTL_USER_TO_KERN(dir) ? &tmp : k_ptr;
 
-	ret = do_proc_dointvec_ms_jiffies_conv(negp, u_ptr, ip, dir, table);
+	ret = do_proc_int_conv_ms_jiffies(negp, u_ptr, ip, dir, table);
 	if (ret)
 		return ret;
 
@@ -1062,7 +1038,7 @@ int proc_dointvec_jiffies(const struct ctl_table *table, int dir,
 			  void *buffer, size_t *lenp, loff_t *ppos)
 {
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos,
-				do_proc_dointvec_jiffies_conv);
+				do_proc_int_conv_jiffies);
 }
 
 int proc_dointvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
@@ -1090,8 +1066,10 @@ int proc_dointvec_ms_jiffies_minmax(const struct ctl_table *table, int dir,
 int proc_dointvec_userhz_jiffies(const struct ctl_table *table, int dir,
 				 void *buffer, size_t *lenp, loff_t *ppos)
 {
+	if (USER_HZ < HZ)
+		return -EINVAL;
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos,
-				do_proc_dointvec_userhz_jiffies_conv);
+				do_proc_int_conv_userhz_jiffies);
 }
 
 /**
@@ -1113,7 +1091,7 @@ int proc_dointvec_ms_jiffies(const struct ctl_table *table, int dir, void *buffe
 		size_t *lenp, loff_t *ppos)
 {
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos,
-				do_proc_dointvec_ms_jiffies_conv);
+				do_proc_int_conv_ms_jiffies);
 }
 
 /**

-- 
2.50.1

