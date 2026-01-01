From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 01 Jan 2026 13:57:10 +0100
Subject: [PATCH v2 6/9] sysctl: Rename do_proc_dotypevec macro to
 do_proc_typevec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-jag-dovec_consolidate-v2-6-ff918f753ba9@kernel.org>
References: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
In-Reply-To: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4776;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=EfuZhzyOMaVV5FDyRZb2ekLBnEai3Frd1m0Nc1g3+zI=;
 b=kA0DAAoBupfNUreWQU8ByyZiAGlWby2heWf9jcxP2vhvsBmV3lAISfBPXvVhNCg19pyfxIy/M
 4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpVm8tAAoJELqXzVK3lkFP4/0L/A/v
 hGEofZz9w7ZA4yvb3Ml02P3+3enPRIQm0uZVE3j9K0wmjx4Zx8vwwbDU9Gb66iJ5VtDAEnMP6K7
 cmwQ1e1lueC/v/JELJkHBihtSaVw+ou6CUGd7z+S72hjg5LHAdYoLfJHAfj6zOIb/tBjgjXYk4t
 Dc2sg02m/TnuCChNlUUU2cwfu3DeG6tahk5c346iKI3XRWSEoabHP+Xpogn9o0pg3k1RA0EXhAi
 on2KVcbbhNi8pfZrrCevWeXzesx1T6N8uYUSwkepJ0OjZZqfHaHGA271tPKUwjzGJ0t9q/o0moV
 +GlxvgnuXEvTAFapkhfxSBdLUH2Mn8G8smlsTFSdTcU03/IrtMsBYRB3Eb3FahsvpyGh4ymVqqH
 FnPV1l4FBcoPhhRqxgXhyfuoLx3g1ftKIeUY4hckbYGs/iTcC8iN4FR7vrmZdMm26qz836SyOXs
 U0Dai1pPIx3NVgMpmaXiS8URzNdMN7IxrvTxzrlr+SDsB6tUxRjLnnnq1tTA==
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the do..do from the proc vector functions. The redundant "do"
only adds confusion to the already large amount of functions in sysctl.c

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 37 ++++++++++++++++++-------------------
 1 file changed, 18 insertions(+), 19 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 5bc1bd3d415be2552f085111852f63ddefb05894..b90924944ad52bcd3347cf5ca7c87ac9455eb70d 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -576,8 +576,8 @@ static const char proc_wspace_sep[] = { ' ', '\t', '\n' };
  * Do not export this macro outside the sysctl subsys.
  * It is meant to generate static functions only
  */
-#define do_proc_dotypevec(T) \
-static int do_proc_do##T##vec(const struct ctl_table *table, int dir, \
+#define do_proc_typevec(T) \
+static int do_proc_##T##vec(const struct ctl_table *table, int dir, \
 		  void *buffer, size_t *lenp, loff_t *ppos, \
 		  int (*conv)(bool *negp, ulong *u_ptr, T *k_ptr, \
 			      int dir, const struct ctl_table *table)) \
@@ -649,9 +649,9 @@ out: \
 	return err; \
 }
 
-do_proc_dotypevec(int)
-do_proc_dotypevec(ulong)
-do_proc_dotypevec(uint)
+do_proc_typevec(int)
+do_proc_typevec(ulong)
+do_proc_typevec(uint)
 
 /**
  * proc_douintvec_conv - read a vector of unsigned ints with a custom converter
@@ -678,7 +678,7 @@ int proc_douintvec_conv(const struct ctl_table *table, int dir, void *buffer,
 	if (!conv)
 		conv = do_proc_uint_conv;
 
-	return do_proc_douintvec(table, dir, buffer, lenp, ppos, conv);
+	return do_proc_uintvec(table, dir, buffer, lenp, ppos, conv);
 }
 
 /**
@@ -737,7 +737,7 @@ int proc_dobool(const struct ctl_table *table, int dir, void *buffer,
 int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 		  size_t *lenp, loff_t *ppos)
 {
-	return do_proc_dointvec(table, dir, buffer, lenp, ppos, do_proc_int_conv);
+	return do_proc_intvec(table, dir, buffer, lenp, ppos, do_proc_int_conv);
 }
 
 /**
@@ -756,8 +756,7 @@ int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 		size_t *lenp, loff_t *ppos)
 {
-	return do_proc_douintvec(table, dir, buffer, lenp, ppos,
-				 do_proc_uint_conv);
+	return do_proc_uintvec(table, dir, buffer, lenp, ppos, do_proc_uint_conv);
 }
 
 /**
@@ -780,8 +779,8 @@ int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 		  void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return do_proc_dointvec(table, dir, buffer, lenp, ppos,
-				do_proc_int_conv_minmax);
+	return do_proc_intvec(table, dir, buffer, lenp, ppos,
+			      do_proc_int_conv_minmax);
 }
 
 /**
@@ -807,8 +806,8 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 int proc_douintvec_minmax(const struct ctl_table *table, int dir,
 			  void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return do_proc_douintvec(table, dir, buffer, lenp, ppos,
-				 do_proc_uint_conv_minmax);
+	return do_proc_uintvec(table, dir, buffer, lenp, ppos,
+			       do_proc_uint_conv_minmax);
 }
 
 /**
@@ -851,8 +850,8 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int dir,
 		tmp.extra2 = (unsigned int *) &max;
 
 	val = READ_ONCE(*data);
-	res = do_proc_douintvec(&tmp, dir, buffer, lenp, ppos,
-				do_proc_uint_conv_minmax);
+	res = do_proc_uintvec(&tmp, dir, buffer, lenp, ppos,
+			      do_proc_uint_conv_minmax);
 	if (res)
 		return res;
 	if (SYSCTL_USER_TO_KERN(dir))
@@ -982,7 +981,7 @@ int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
 				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
 					    int dir, const struct ctl_table *table))
 {
-	return do_proc_doulongvec(table, dir, buffer, lenp, ppos, conv);
+	return do_proc_ulongvec(table, dir, buffer, lenp, ppos, conv);
 }
 
 /**
@@ -1004,8 +1003,8 @@ int proc_doulongvec_minmax_conv(const struct ctl_table *table, int dir,
 int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 			   void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return do_proc_doulongvec(table, dir, buffer, lenp, ppos,
-				  do_proc_ulong_conv);
+	return do_proc_ulongvec(table, dir, buffer, lenp, ppos,
+				do_proc_ulong_conv);
 }
 
 int proc_dointvec_conv(const struct ctl_table *table, int dir, void *buffer,
@@ -1015,7 +1014,7 @@ int proc_dointvec_conv(const struct ctl_table *table, int dir, void *buffer,
 {
 	if (!conv)
 		conv = do_proc_int_conv;
-	return do_proc_dointvec(table, dir, buffer, lenp, ppos, conv);
+	return do_proc_intvec(table, dir, buffer, lenp, ppos, conv);
 }
 
 /**

-- 
2.50.1

