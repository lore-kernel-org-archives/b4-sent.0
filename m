From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 01 Jan 2026 13:57:06 +0100
Subject: [PATCH v2 2/9] sysctl: Replace do_proc_dointvec with a
 type-generic macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-jag-dovec_consolidate-v2-2-ff918f753ba9@kernel.org>
References: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
In-Reply-To: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5259;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=MfwFhvcQgwESGWC+Nu+uixcRT1E0Tgwr+3WslGED45k=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlWbyrp75EOe+2gLc2hPbD6r35ilHbCeY305
 7A3vWgCgWfm+IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpVm8qAAoJELqXzVK3
 lkFPV7ML+wUy9hbbmovESRDRANlhSfcLGSUSbrrClGNULVc88aA8ObOYM25i1dTkZlEFp+1pbJ2
 nXOOx9rTpzKXQy0X+hRuWUW1i60n8pnfnkdV5NmfZwpCO0N7Hf9XvNig5JwdIRa7SORyYidvZvB
 kNtlLZvvHx2B+37pkFdB1whl20f7mAX3uNkKNidxZjTEKgW4GwO1BfCbCHdW6TrxX2LkXL/FcX/
 DebV5BtE76uhgaggC4rKNdl5pVCIDHKE5sGtIvFWo0+Q2jEW2FtB8cRuTVfiRzBTM0HLOw83cL+
 mfPci+ln3YvAOslGAOmVNebFq5bm2WgGx57cfub7yai/Z6RtRZh6qVa0Dg2v8v/Mv17PZdwjdHN
 Gtoan23y6s9N/5OWj9L/FELaVj8pe/Mizdf6d7q2sk2EIf0PnqgGbb7pdVoAB1mVbShTfigSZ7P
 o3AN4vuuU5RtZERn8Q7hA6/2QpycVZyouwxbrWoA/xwkgNtv1SF3Tfi01RBRPm5SVcDeUl/Iua9
 nw=
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
argument in the converter call back function.

Initialize the neg variable to false to ensure that unsigned types do
not inadvertently assign negative values to user space. Return an
-EINVAL when user space tries to assign a negative value to an unsigned
variable. Add a comment to clarify that the macro is **not** designed to
be exported outside of sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 144 ++++++++++++++++++++++++++++++--------------------------
 1 file changed, 77 insertions(+), 67 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 284ad6c277e8b52177cca3153acf02ff39de17f0..64f88c0338987ac9568713dd15db99f14553e82b 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -572,75 +572,85 @@ static int do_proc_int_conv_minmax(bool *negp, unsigned long *u_ptr, int *k_ptr,
 
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
+		bool neg = false; \
+\
+		if (SYSCTL_USER_TO_KERN(dir)) { \
+			proc_skip_spaces(&p, &left); \
+\
+			if (!left) \
+				break; \
+			err = proc_get_long(&p, &left, &lval, &neg, \
+					    proc_wspace_sep, \
+					    sizeof(proc_wspace_sep), NULL); \
+			if (!err && neg && is_unsigned_type(T)) \
+				err = -EINVAL; \
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

