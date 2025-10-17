From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 17 Oct 2025 10:32:13 +0200
Subject: [PATCH 3/7] sysctl: Move UINT converter macros to sysctl header
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251017-jag-sysctl_jiffies-v1-3-175d81dfdf82@kernel.org>
References: <20251017-jag-sysctl_jiffies-v1-0-175d81dfdf82@kernel.org>
In-Reply-To: <20251017-jag-sysctl_jiffies-v1-0-175d81dfdf82@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4816;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=0OjnJiYGVGjDynjvHn5XLycsIiIb+BowncnpR4xepGI=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjx/0CUvvVn2u5K8hSOidQ/tDLn/ZoBkO+Mf
 0DOFi4952J0DokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8f9AAAoJELqXzVK3
 lkFPlDcL/iVvo3C3ne1X/TP/Nwgr9Idr+QgPEHWWfWOc7zUnd9gFUw/tl1gLDygH1DOSl1ohxUF
 JFT4T5+Nvdze/bHjcHa7vrqLE4Sr09Gx/wCPGfEyagT5FLDhbeYwp3MigtDewKIS/nDkdGe9Zle
 y5LxmjxXIEYeTbog9nQjHktf2hDCXHy77VKEK+5Kys7lSneyVOizQErYE/iZMEOuLywD9Hzj4GM
 +OdWfigmzBmwcBFrYcNiU3BLhaNGuFRxKBPPgXiQjHdKovUgSwItAXLPPCvfhdtyqPzWSm7+BYa
 X9WPucQ2LtJfhj742AnnQZ4ZH71obLXEGpesNbgyV9djwBLTbzRPr3fw/OlEMyZX+Yc5SJ+kO8t
 TU1j226NZkPvpx0ILKWvaBT+rgppdaZ5ymapxE73tIDIQetdWn4SlmDMQYg9y4kCKNp/RmgUp76
 GtJnIs+fN57v/UO6M1m5cnBzRnfyJ90LzXEgWPMzuxaL/gq6oNQmYbx8eCGW8/dq1Wzc0LaPBb5
 0o=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move SYSCTL_USER_TO_KERN_UINT_CONV and SYSCTL_UINT_CONV_CUSTOM macros to
include/linux/sysctl.h. No need to embed sysctl_kern_to_user_uint_conv
in a macro as it will not need a custom kernel pointer operation. This
is a preparation commit to enable jiffies converter creation outside
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 include/linux/sysctl.h | 40 ++++++++++++++++++++++++++++++++++++++++
 kernel/sysctl.c        | 42 ++----------------------------------------
 2 files changed, 42 insertions(+), 40 deletions(-)

diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 967a9ad6b4200266e2d9c6cfa9ee58fb8bf51090..faeeb2feefb83d5b57e67f5cbf2eadf79dd03fb2 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -134,6 +134,45 @@ int do_proc_int_conv##name(bool *negp, unsigned long *u_ptr, int *k_ptr,\
 	return 0;							\
 }
 
+#define SYSCTL_USER_TO_KERN_UINT_CONV(name, u_ptr_op)		\
+int sysctl_user_to_kern_uint_conv##name(const unsigned long *u_ptr,\
+					unsigned int *k_ptr)	\
+{								\
+	unsigned long u = u_ptr_op(*u_ptr);			\
+	if (u > UINT_MAX)					\
+		return -EINVAL;					\
+	WRITE_ONCE(*k_ptr, u);					\
+	return 0;						\
+}
+
+#define SYSCTL_UINT_CONV_CUSTOM(name, user_to_kern, kern_to_user,	\
+				k_ptr_range_check)			\
+int do_proc_uint_conv##name(unsigned long *u_ptr, unsigned int *k_ptr,	\
+			   int dir, const struct ctl_table *tbl)	\
+{									\
+	if (SYSCTL_KERN_TO_USER(dir))					\
+		return kern_to_user(u_ptr, k_ptr);			\
+									\
+	if (k_ptr_range_check) {					\
+		unsigned int tmp_k;					\
+		int ret;						\
+		if (!tbl)						\
+			return -EINVAL;					\
+		ret = user_to_kern(u_ptr, &tmp_k);			\
+		if (ret)						\
+			return ret;					\
+		if ((tbl->extra1 &&					\
+		     *(unsigned int *)tbl->extra1 > tmp_k) ||		\
+		    (tbl->extra2 &&					\
+		     *(unsigned int *)tbl->extra2 < tmp_k))		\
+			return -ERANGE;					\
+		WRITE_ONCE(*k_ptr, tmp_k);				\
+	} else								\
+		return user_to_kern(u_ptr, k_ptr);			\
+	return 0;							\
+}
+
+
 extern const unsigned long sysctl_long_vals[];
 
 typedef int proc_handler(const struct ctl_table *ctl, int write, void *buffer,
@@ -166,6 +205,7 @@ int proc_doulongvec_ms_jiffies_minmax(const struct ctl_table *table, int, void *
 int proc_do_large_bitmap(const struct ctl_table *, int, void *, size_t *, loff_t *);
 int proc_do_static_key(const struct ctl_table *table, int write, void *buffer,
 		size_t *lenp, loff_t *ppos);
+int sysctl_kern_to_user_uint_conv(unsigned long *u_ptr, const unsigned int *k_ptr);
 
 /*
  * Register a set of sysctl names by calling register_sysctl
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 70cf23d9834ef4e6b95ab80a3dc7a06237742793..f3d2385f88494da1e5ba7ee1fbb575d2545d7d84 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -387,54 +387,16 @@ static SYSCTL_INT_CONV_CUSTOM(_ms_jiffies_minmax,
 			      sysctl_user_to_kern_int_conv_ms,
 			      sysctl_kern_to_user_int_conv_ms, true)
 
-#define SYSCTL_USER_TO_KERN_UINT_CONV(name, u_ptr_op)		\
-int sysctl_user_to_kern_uint_conv##name(const unsigned long *u_ptr,\
-					unsigned int *k_ptr)	\
-{								\
-	unsigned long u = u_ptr_op(*u_ptr);			\
-	if (u > UINT_MAX)					\
-		return -EINVAL;					\
-	WRITE_ONCE(*k_ptr, u);					\
-	return 0;						\
-}
-
 static SYSCTL_USER_TO_KERN_UINT_CONV(,SYSCTL_CONV_IDENTITY)
 
-static int sysctl_kern_to_user_uint_conv(unsigned long *u_ptr,
-					 const unsigned int *k_ptr)
+int sysctl_kern_to_user_uint_conv(unsigned long *u_ptr,
+				  const unsigned int *k_ptr)
 {
 	unsigned int val = READ_ONCE(*k_ptr);
 	*u_ptr = (unsigned long)val;
 	return 0;
 }
 
-#define SYSCTL_UINT_CONV_CUSTOM(name, user_to_kern, kern_to_user,	\
-				k_ptr_range_check)			\
-int do_proc_uint_conv##name(unsigned long *u_ptr, unsigned int *k_ptr,	\
-			   int dir, const struct ctl_table *tbl)	\
-{									\
-	if (SYSCTL_KERN_TO_USER(dir))					\
-		return kern_to_user(u_ptr, k_ptr);			\
-									\
-	if (k_ptr_range_check) {					\
-		unsigned int tmp_k;					\
-		int ret;						\
-		if (!tbl)						\
-			return -EINVAL;					\
-		ret = user_to_kern(u_ptr, &tmp_k);			\
-		if (ret)						\
-			return ret;					\
-		if ((tbl->extra1 &&					\
-		     *(unsigned int *)tbl->extra1 > tmp_k) ||		\
-		    (tbl->extra2 &&					\
-		     *(unsigned int *)tbl->extra2 < tmp_k))		\
-			return -ERANGE;					\
-		WRITE_ONCE(*k_ptr, tmp_k);				\
-	} else								\
-		return user_to_kern(u_ptr, k_ptr);			\
-	return 0;							\
-}
-
 static SYSCTL_UINT_CONV_CUSTOM(, sysctl_user_to_kern_uint_conv,
 			       sysctl_kern_to_user_uint_conv, false)
 static SYSCTL_UINT_CONV_CUSTOM(_minmax, sysctl_user_to_kern_uint_conv,

-- 
2.50.1

