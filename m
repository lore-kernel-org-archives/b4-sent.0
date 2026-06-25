From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 25 Jun 2026 22:38:22 +0200
Subject: [PATCH v3 10/10] sysctl: Replace do_proc_typevec macro with
 do_proc_vec function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-jag-dovec_consolidate-v3-10-176ee192bcaf@kernel.org>
References: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
In-Reply-To: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=11125;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=x4JIywcKohsYqPu2d/054gOhbgwa4gu+B5G62pxJOQ4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGo9keTAi6L+aE4lphoBTUkv+FpcTZt2CDq9u
 Q6xfVOjNZTOq4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqPZHkAAoJELqXzVK3
 lkFPvBAL/1CU0AQ2MGCn2hEiPujMlaPI0YGJo3utvI0IOxZSMBUbPGFAf8+sdv48wqQ3jvS+aay
 xqllCbmdVVZgwTRmvgp36JTyHyy3kwS9jjPbeYfO2Gmw3SaZSr++rSTdQy2TZloT7V62EjiF/1U
 lI5R/tyTE+UHQRPHLUSe9GfnB2osjDr+7CDKiw1m6Pk+nccPBQoMR0tY4h5v2O9378IrVorGx4/
 jlI6NJTnRY1JMbxP2xLKy0kwr7cT8m0uBD6ercSh0gvQt4iIqef4GtNUvMUyrPGXHucy7ZvBcUl
 8pDTE3lKQT+GlmUG9BEaufQ9ASqBzvSdvu/qbN2YXvZZ4hjeYJ3cYgdNVYb0acQtCCSKBYC+ZT9
 Qru3+kfZ1yWChOwuLIYgIGy127nm2+2fpApegL0yB71x6wdi94sMxjo4o5HnrLozFj6S018O5fd
 sYu1e2F/GiL1NLtov5+CsLKvP8ZtD4zNk/45xUr9UXfimji/+n7mRRV5sD6o/V1JT+JXvojVsB9
 Dw=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace macro with a single runtime static function, do_proc_vec(),
parameterised by proc_vec_type enum which defines the type being
processed and selects which converter is "live". Signedness and size are
calculated based on proc_vec_type and table->data is now walked as raw
bytes and advanced by the element size; the converter still performs the
actual typed load/store.

Pass converter as a union to avoid a cast from void*. The public
proc_do{int,uint,ulong}vec_conv() prototypes and all converter
signatures in kernel/, fs/ and the header are therefore unchanged.

Moving away from a macro makes debugging easier. No functional change
intended.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 243 +++++++++++++++++++++++++++++++++++---------------------
 1 file changed, 154 insertions(+), 89 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index a26011c3967faffaa19b358038c35d7f8868a051..4abd91ea97f70559ba2716f9da9109c08ba43e6b 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -590,85 +590,145 @@ static int do_proc_int_conv_minmax(bool *negp, unsigned long *u_ptr, int *k_ptr,
 static const char proc_wspace_sep[] = { ' ', '\t', '\n' };
 
 /*
- * Do not export this macro outside the sysctl subsys.
- * It is meant to generate static functions only
+ * Element type processed by do_proc_vec(). The tag selects the element size
+ * and signedness, and it selects which member of union proc_vec_conv is live.
  */
-#define do_proc_typevec(T) \
-static int do_proc_##T##vec(const struct ctl_table *table, int dir, \
-		  void *buffer, size_t *lenp, loff_t *ppos, \
-		  int (*conv)(bool *negp, ulong *u_ptr, T *k_ptr, \
-			      int dir, const struct ctl_table *table)) \
-{ \
-	T *i; \
-	int vleft, first = 1, err = 0; \
-	size_t left; \
-	char *p; \
-\
-	if (!table->data || !table->maxlen || !*lenp || \
-	    (*ppos && SYSCTL_KERN_TO_USER(dir))) { \
-		*lenp = 0; \
-		return 0; \
-	} \
-\
-	i = (typeof(i)) table->data; \
-	vleft = table->maxlen / sizeof(*i); \
-	left = *lenp; \
-\
-	if (SYSCTL_USER_TO_KERN(dir)) { \
-		if (proc_first_pos_non_zero_ignore(ppos, table)) \
-			goto out; \
-\
-		if (left > PAGE_SIZE - 1) \
-			left = PAGE_SIZE - 1; \
-		p = buffer; \
-	} \
-\
-	for (; left && vleft--; i++, first = 0) { \
-		unsigned long lval; \
-		bool neg = false; \
-\
-		if (SYSCTL_USER_TO_KERN(dir)) { \
-			proc_skip_spaces(&p, &left); \
-\
-			if (!left) \
-				break; \
-			err = proc_get_long(&p, &left, &lval, &neg, \
-					    proc_wspace_sep, \
-					    sizeof(proc_wspace_sep), NULL); \
-			if (!err && neg && is_unsigned_type(T)) \
-				err = -EINVAL; \
-			if (err) \
-				break; \
-			if (conv(&neg, &lval, i, dir, table)) { \
-				err = -EINVAL; \
-				break; \
-			} \
-		} else { \
-			if (conv(&neg, &lval, i, dir, table)) { \
-				err = -EINVAL; \
-				break; \
-			} \
-			if (!first) \
-				proc_put_char(&buffer, &left, '\t'); \
-			proc_put_long(&buffer, &left, lval, neg); \
-		} \
-	} \
-\
-	if (SYSCTL_KERN_TO_USER(dir) && !first && left && !err) \
-		proc_put_char(&buffer, &left, '\n'); \
-	if (SYSCTL_USER_TO_KERN(dir) && !err && left) \
-		proc_skip_spaces(&p, &left); \
-	if (SYSCTL_USER_TO_KERN(dir) && first) \
-		return err ? : -EINVAL; \
-	*lenp -= left; \
-out: \
-	*ppos += *lenp; \
-	return err; \
+enum proc_vec_type {
+	PROC_VEC_INT,
+	PROC_VEC_UINT,
+	PROC_VEC_ULONG,
+};
+
+/*
+ * Converter passed to do_proc_vec(). Only the member matching the
+ * enum proc_vec_type tag is ever read, so every dispatch stays fully typed and
+ * no void * converter pointer is needed.
+ */
+union proc_vec_conv {
+	int (*int_conv)(bool *negp, ulong *u_ptr, int *k_ptr,
+			int dir, const struct ctl_table *table);
+	int (*uint_conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
+			 int dir, const struct ctl_table *table);
+	int (*ulong_conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
+			  int dir, const struct ctl_table *table);
+};
+
+/*
+ * Dispatch to the converter member selected by @type. @k_ptr walks
+ * table->data as raw bytes and is cast back to the element type here.
+ */
+static int proc_vec_conv(enum proc_vec_type type, union proc_vec_conv conv,
+			 bool *negp, ulong *u_ptr, char *k_ptr, int dir,
+			 const struct ctl_table *table)
+{
+	switch (type) {
+	case PROC_VEC_INT:
+		return conv.int_conv(negp, u_ptr, (int *)k_ptr, dir, table);
+	case PROC_VEC_UINT:
+		return conv.uint_conv(negp, u_ptr, (uint *)k_ptr, dir, table);
+	case PROC_VEC_ULONG:
+		return conv.ulong_conv(negp, u_ptr, (ulong *)k_ptr, dir, table);
+	}
+	return -EINVAL;
 }
 
-do_proc_typevec(int)
-do_proc_typevec(ulong)
-do_proc_typevec(uint)
+/*
+ * Read/write a vector of @type elements. The element size and signedness are
+ * derived from @type, so a single runtime function replaces the per-type
+ * variants. table->data is walked as raw bytes (@i) advanced by @size; the
+ * converter performs the actual typed load/store.
+ */
+static int do_proc_vec(const struct ctl_table *table, int dir,
+		       void *buffer, size_t *lenp, loff_t *ppos,
+		       enum proc_vec_type type, union proc_vec_conv conv)
+{
+	int vleft, first = 1, err = 0;
+	size_t left, size;
+	bool is_unsigned;
+	char *i, *p;
+
+	switch (type) {
+	case PROC_VEC_INT:
+		size = sizeof(int);
+		is_unsigned = false;
+		break;
+	case PROC_VEC_UINT:
+		size = sizeof(uint);
+		is_unsigned = true;
+		break;
+	case PROC_VEC_ULONG:
+		size = sizeof(ulong);
+		is_unsigned = true;
+		break;
+	default:
+		return -EINVAL;
+	}
+
+	if (!table->data || !table->maxlen || !*lenp ||
+	    (*ppos && SYSCTL_KERN_TO_USER(dir))) {
+		*lenp = 0;
+		return 0;
+	}
+
+	i = table->data;
+	vleft = table->maxlen / size;
+	left = *lenp;
+
+	/* uint arrays are not supported, *Do not* add support for them. */
+	if (type == PROC_VEC_UINT && vleft != 1)
+		return -EINVAL;
+
+	if (SYSCTL_USER_TO_KERN(dir)) {
+		if (proc_first_pos_non_zero_ignore(ppos, table))
+			goto out;
+
+		if (left > PAGE_SIZE - 1)
+			left = PAGE_SIZE - 1;
+		p = buffer;
+	}
+
+	for (; left && vleft--; i += size, first = 0) {
+		unsigned long lval;
+		bool neg = false;
+
+		if (SYSCTL_USER_TO_KERN(dir)) {
+			proc_skip_spaces(&p, &left);
+
+			if (!left)
+				break;
+			err = proc_get_long(&p, &left, &lval, &neg,
+					    proc_wspace_sep,
+					    sizeof(proc_wspace_sep), NULL);
+			if (!err && neg && is_unsigned)
+				err = -EINVAL;
+			if (err)
+				break;
+			if (proc_vec_conv(type, conv, &neg, &lval, i, dir, table)) {
+				err = -EINVAL;
+				break;
+			}
+		} else {
+			if (proc_vec_conv(type, conv, &neg, &lval, i, dir, table)) {
+				err = -EINVAL;
+				break;
+			}
+			if (!first)
+				proc_put_char(&buffer, &left, '\t');
+			proc_put_long(&buffer, &left, lval, neg);
+		}
+	}
+
+	if (SYSCTL_KERN_TO_USER(dir) && !first && left && !err)
+		proc_put_char(&buffer, &left, '\n');
+	if (SYSCTL_USER_TO_KERN(dir) && !err && left)
+		proc_skip_spaces(&p, &left);
+	if (SYSCTL_USER_TO_KERN(dir) && first)
+		return err ? : -EINVAL;
+	*lenp -= left;
+out:
+	*ppos += *lenp;
+	return err;
+}
 
 /**
  * proc_douintvec_conv - read a vector of unsigned ints with a custom converter
@@ -695,7 +755,8 @@ int proc_douintvec_conv(const struct ctl_table *table, int dir, void *buffer,
 	if (!conv)
 		conv = do_proc_uint_conv;
 
-	return do_proc_uintvec(table, dir, buffer, lenp, ppos, conv);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
+			   (union proc_vec_conv){ .uint_conv = conv });
 }
 
 /**
@@ -754,7 +815,8 @@ int proc_dobool(const struct ctl_table *table, int dir, void *buffer,
 int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 		  size_t *lenp, loff_t *ppos)
 {
-	return do_proc_intvec(table, dir, buffer, lenp, ppos, do_proc_int_conv);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_INT,
+			   (union proc_vec_conv){ .int_conv = do_proc_int_conv });
 }
 
 /**
@@ -773,7 +835,8 @@ int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 		size_t *lenp, loff_t *ppos)
 {
-	return do_proc_uintvec(table, dir, buffer, lenp, ppos, do_proc_uint_conv);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
+			   (union proc_vec_conv){ .uint_conv = do_proc_uint_conv });
 }
 
 /**
@@ -796,8 +859,8 @@ int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 		  void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return do_proc_intvec(table, dir, buffer, lenp, ppos,
-			      do_proc_int_conv_minmax);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_INT,
+			   (union proc_vec_conv){ .int_conv = do_proc_int_conv_minmax });
 }
 
 /**
@@ -823,8 +886,8 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 int proc_douintvec_minmax(const struct ctl_table *table, int dir,
 			  void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return do_proc_uintvec(table, dir, buffer, lenp, ppos,
-			       do_proc_uint_conv_minmax);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
+			   (union proc_vec_conv){ .uint_conv = do_proc_uint_conv_minmax });
 }
 
 /**
@@ -867,8 +930,8 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int dir,
 		tmp.extra2 = (unsigned int *) &max;
 
 	val = READ_ONCE(*data);
-	res = do_proc_uintvec(&tmp, dir, buffer, lenp, ppos,
-			      do_proc_uint_conv_minmax);
+	res = do_proc_vec(&tmp, dir, buffer, lenp, ppos, PROC_VEC_UINT,
+			  (union proc_vec_conv){ .uint_conv = do_proc_uint_conv_minmax });
 	if (res)
 		return res;
 	if (SYSCTL_USER_TO_KERN(dir))
@@ -998,7 +1061,8 @@ int proc_doulongvec_conv(const struct ctl_table *table, int dir,
 				int (*conv)(bool *negp, ulong *u_ptr, ulong *k_ptr,
 					    int dir, const struct ctl_table *table))
 {
-	return do_proc_ulongvec(table, dir, buffer, lenp, ppos, conv);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_ULONG,
+			   (union proc_vec_conv){ .ulong_conv = conv });
 }
 
 /**
@@ -1020,8 +1084,8 @@ int proc_doulongvec_conv(const struct ctl_table *table, int dir,
 int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 			   void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return do_proc_ulongvec(table, dir, buffer, lenp, ppos,
-				do_proc_ulong_conv);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_ULONG,
+			   (union proc_vec_conv){ .ulong_conv = do_proc_ulong_conv });
 }
 
 /**
@@ -1045,7 +1109,8 @@ int proc_dointvec_conv(const struct ctl_table *table, int dir, void *buffer,
 {
 	if (!conv)
 		conv = do_proc_int_conv;
-	return do_proc_intvec(table, dir, buffer, lenp, ppos, conv);
+	return do_proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_INT,
+			   (union proc_vec_conv){ .int_conv = conv });
 }
 
 /**

-- 
2.50.1

