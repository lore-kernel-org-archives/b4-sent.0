From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 19 Dec 2025 13:15:53 +0100
Subject: [PATCH 2/9] sysctl: Replace do_proc_dointvec with a type-generic
 macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251219-jag-dovec_consolidate-v1-2-1413b92c6040@kernel.org>
References: <20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org>
In-Reply-To: <20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4959;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=C2CiSX+3NOlsc9EOUTFYNZR5sIzoS6WVYi1ixR9Wg44=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlFQgVv4z9XDuX1mY5xQRjIopXVim68ykErq
 95+2gBockDcrIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpRUIFAAoJELqXzVK3
 lkFP2lEMAJUgaWSzGeFvf8UYl30vF9V7ekLPEMAKE0htODrEJoJCKpJBAlv6Abj7VbKR772RFje
 1HWOO6M8IxNZrsQ0iBSayj1SiSrfvcwx8FYJxlywSr5Wr3BwfeclN0dWbgI3tVHVfW1ymdwDEuA
 +TZtN/COJZRaGck4Kd/GYYqf95SgoUKhV96tnhhDzGh2xML4jfBItN4O2DK2YZkoiWlTNfUTVpt
 FOrc1kSl4C3UrCCRiYu5vg6kGsVkl33hWxVmPkvsn7qeRBmxZ/oEjB0Hq1s/+o2g9m87QcuEjsh
 WnLK8N4I1oA5nUy3XwL9mlb+5oDa1B8FT+IQs26bc4RjnD8cZlZ92n+QTs88KwkYJj710u33a7n
 R+MaW3Qp2jvMKRw+GcgQu8pkemfEEqP0Zzl9aewvTU1biFMfJBxCaknqJllvIr6FKWcGK7JQcgl
 iNAVCPDbUpHiWcOIXcdAcIG3CUYfV9dAQmeRLIcyMICjZz5fhChubyJJ5FlYq3mpJ3sesjxGHS3
 0g=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replaces do_proc_dointvec with do_proc_dotypevec macro. For now, it only
generates the integer function, but it will bring together the logic for
int, uint and ulong proc vector functions. It is parametrized on the
kernel pointer type being processed and generates a "do_proc_do##T##vec"
(where T is the type) function. The parametrization is needed for
advancing the for loop with "++" and affects the type of the k_ptr
argument in the converter call back function. Add a comment to clarify
that the macro is **not** designed to be exported outside of sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 142 ++++++++++++++++++++++++++++++--------------------------
 1 file changed, 75 insertions(+), 67 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 284ad6c277e8b52177cca3153acf02ff39de17f0..66db2ac69a91ac4b200cb8906dcb76209bee28bb 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -572,75 +572,83 @@ static int do_proc_int_conv_minmax(bool *negp, unsigned long *u_ptr, int *k_ptr,
 
 static const char proc_wspace_sep[] = { ' ', '\t', '\n' };
 
-static int do_proc_dointvec(const struct ctl_table *table, int dir,
-		  void *buffer, size_t *lenp, loff_t *ppos,
-		  int (*conv)(bool *negp, unsigned long *u_ptr, int *k_ptr,
-			      int dir, const struct ctl_table *table))
-{
-	int *i, vleft, first = 1, err = 0;
-	size_t left;
-	char *p;
-
-	if (!table->data || !table->maxlen || !*lenp ||
-	    (*ppos && SYSCTL_KERN_TO_USER(dir))) {
-		*lenp = 0;
-		return 0;
-	}
-
-	i = (int *) table->data;
-	vleft = table->maxlen / sizeof(*i);
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
-
-	for (; left && vleft--; i++, first=0) {
-		unsigned long lval;
-		bool neg;
-
-		if (SYSCTL_USER_TO_KERN(dir)) {
-			proc_skip_spaces(&p, &left);
-
-			if (!left)
-				break;
-			err = proc_get_long(&p, &left, &lval, &neg,
-					     proc_wspace_sep,
-					     sizeof(proc_wspace_sep), NULL);
-			if (err)
-				break;
-			if (conv(&neg, &lval, i, 1, table)) {
-				err = -EINVAL;
-				break;
-			}
-		} else {
-			if (conv(&neg, &lval, i, 0, table)) {
-				err = -EINVAL;
-				break;
-			}
-			if (!first)
-				proc_put_char(&buffer, &left, '\t');
-			proc_put_long(&buffer, &left, lval, neg);
-		}
-	}
-
-	if (SYSCTL_KERN_TO_USER(dir) && !first && left && !err)
-		proc_put_char(&buffer, &left, '\n');
-	if (SYSCTL_USER_TO_KERN(dir) && !err && left)
-		proc_skip_spaces(&p, &left);
-	if (SYSCTL_USER_TO_KERN(dir) && first)
-		return err ? : -EINVAL;
-	*lenp -= left;
-out:
-	*ppos += *lenp;
-	return err;
+/*
+ * Do not export this macro outside the sysctl subsys.
+ * It is meant to generate static functions only
+ */
+#define do_proc_dotypevec(T) \
+static int do_proc_do##T##vec(const struct ctl_table *table, int dir, \
+		  void *buffer, size_t *lenp, loff_t *ppos, \
+		  int (*conv)(bool *negp, ulong *u_ptr, T *k_ptr, \
+			      int dir, const struct ctl_table *table)) \
+{ \
+	T *i; \
+	int vleft, first = 1, err = 0; \
+	size_t left; \
+	char *p; \
+\
+	if (!table->data || !table->maxlen || !*lenp || \
+	    (*ppos && SYSCTL_KERN_TO_USER(dir))) { \
+		*lenp = 0; \
+		return 0; \
+	} \
+\
+	i = (typeof(i)) table->data; \
+	vleft = table->maxlen / sizeof(*i); \
+	left = *lenp; \
+\
+	if (SYSCTL_USER_TO_KERN(dir)) { \
+		if (proc_first_pos_non_zero_ignore(ppos, table)) \
+			goto out; \
+\
+		if (left > PAGE_SIZE - 1) \
+			left = PAGE_SIZE - 1; \
+		p = buffer; \
+	} \
+\
+	for (; left && vleft--; i++, first = 0) { \
+		unsigned long lval; \
+		bool neg; \
+\
+		if (SYSCTL_USER_TO_KERN(dir)) { \
+			proc_skip_spaces(&p, &left); \
+\
+			if (!left) \
+				break; \
+			err = proc_get_long(&p, &left, &lval, &neg, \
+					     proc_wspace_sep, \
+					     sizeof(proc_wspace_sep), NULL); \
+			if (err) \
+				break; \
+			if (conv(&neg, &lval, i, dir, table)) { \
+				err = -EINVAL; \
+				break; \
+			} \
+		} else { \
+			if (conv(&neg, &lval, i, dir, table)) { \
+				err = -EINVAL; \
+				break; \
+			} \
+			if (!first) \
+				proc_put_char(&buffer, &left, '\t'); \
+			proc_put_long(&buffer, &left, lval, neg); \
+		} \
+	} \
+\
+	if (SYSCTL_KERN_TO_USER(dir) && !first && left && !err) \
+		proc_put_char(&buffer, &left, '\n'); \
+	if (SYSCTL_USER_TO_KERN(dir) && !err && left) \
+		proc_skip_spaces(&p, &left); \
+	if (SYSCTL_USER_TO_KERN(dir) && first) \
+		return err ? : -EINVAL; \
+	*lenp -= left; \
+out: \
+	*ppos += *lenp; \
+	return err; \
 }
 
+do_proc_dotypevec(int)
+
 static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
 			       int (*conv)(unsigned long *u_ptr,

-- 
2.50.1

