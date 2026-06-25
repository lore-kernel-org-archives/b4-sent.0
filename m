From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 25 Jun 2026 22:38:16 +0200
Subject: [PATCH v3 04/10] sysctl: Add negp parameter to douintvec converter
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-jag-dovec_consolidate-v3-4-176ee192bcaf@kernel.org>
References: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
In-Reply-To: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=5962;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=EnSbav8LTBcYKpEx56WF+Li/SNShYacbuabnTj+N/BU=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGo9keBZ2NpWSOB73GD3l6Q+iXMQ5Ae9Q9XK5
 /MFDb5zY4rFM4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqPZHgAAoJELqXzVK3
 lkFPM34L/j72JqvCPKDWnD8XiV2WwaPamg4FxqKvl6qeV3T9xc9ftAg40kqBq0GopHp89h2lh7N
 rYnNaHi1umSJfhnlTKpTQd3fWKxdcEnX28UEPap69yPd0BeVDywA+uN//+Hn1bBo9azhmeGY/O4
 ZAIy/FOcj/OfWOTaWJkuaQ/PD2BQBd4IhzJwmmMBQXz6oSpNGzDgNF6s4sf0vNQbdepveoxUoFQ
 PO3OBvJo7FAagSLmmOZ2Et8p8BENI5FgozxVpRTr2SHqIcA629dyqaIXxMSsnu+iiD9yRwcp6Du
 2tiTQcUwLsFeaGbPSCe4TXaUOsxsZAHLrVW+x/MbCWBTLRPY7OtazhFMyHX2WQcjU649nSeDL2a
 AxCPyA7pOYz1abRQWtN0hhsgPbpJ0J9aw5l9aCY9GISS+xyD/HcGue8bFqPS9/aY1XJtTTIKrly
 5a3+UPacsih1wJzNxBN/LAhbNaryf4hNvy2Nwwnf4HC51zyJ05VEGTGSrZqJmJhtoyyHRM56u66
 yU=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Updates all douintvec converter function signatures to include a bool
*negp parameter. This is a preparation commit required to eventually
generate do_proc_douintvec with a macro. The negp argument will be
ignored as it is not relevant for the uint type. Note that
do_proc_uint_conv_pipe_maxsz in pipe.c is also modified.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/pipe.c              |  2 +-
 include/linux/sysctl.h |  2 +-
 kernel/sysctl.c        | 31 ++++++++++++++++---------------
 3 files changed, 18 insertions(+), 17 deletions(-)

diff --git a/fs/pipe.c b/fs/pipe.c
index 9841648c9cf3e8e569cf6ba5c792624fe92396f5..e399823f8e959347e3916ad7164c9a4a3626d9d3 100644
--- a/fs/pipe.c
+++ b/fs/pipe.c
@@ -1491,7 +1491,7 @@ static int u2k_pipe_maxsz(const ulong *u_ptr, uint *k_ptr)
 	return proc_uint_u2k_conv_uop(u_ptr, k_ptr, round_pipe_size_ul);
 }
 
-static int do_proc_uint_conv_pipe_maxsz(ulong *u_ptr, uint *k_ptr,
+static int do_proc_uint_conv_pipe_maxsz(bool *negp, ulong *u_ptr, uint *k_ptr,
 					int dir, const struct ctl_table *table)
 {
 	return proc_uint_conv(u_ptr, k_ptr, dir, table, true,
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 5c8c17f98513983a459c54eae99d1cc8bd63b011..8f8e357b1f4d377a0891fbc85d34073cd30469b1 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -102,7 +102,7 @@ int proc_douintvec_minmax(const struct ctl_table *table, int write, void *buffer
 		size_t *lenp, loff_t *ppos);
 int proc_douintvec_conv(const struct ctl_table *table, int write, void *buffer,
 			size_t *lenp, loff_t *ppos,
-			int (*conv)(unsigned long *lvalp, unsigned int *valp,
+			int (*conv)(bool *negp, ulong *lvalp, uint *valp,
 				    int write, const struct ctl_table *table));
 int proc_uint_k2u_conv(ulong *u_ptr, const uint *k_ptr);
 int proc_uint_u2k_conv_uop(const ulong *u_ptr, uint *k_ptr,
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 3208633992557c3a6c3e8effcdfa2cb0781e45ba..08a32918d79d9e098bfd95ed95ff30943a38c2d5 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -444,15 +444,15 @@ static int proc_uint_u2k_conv(const ulong *u_ptr, uint *k_ptr)
 	return proc_uint_u2k_conv_uop(u_ptr, k_ptr, NULL);
 }
 
-static int do_proc_uint_conv(ulong *u_ptr, uint *k_ptr, int dir,
+static int do_proc_uint_conv(bool *negp, ulong *u_ptr, uint *k_ptr, int dir,
 			     const struct ctl_table *tbl)
 {
 	return proc_uint_conv(u_ptr, k_ptr, dir, tbl, false,
 			      proc_uint_u2k_conv, proc_uint_k2u_conv);
 }
 
-static int do_proc_uint_conv_minmax(ulong *u_ptr, uint *k_ptr, int dir,
-				    const struct ctl_table *tbl)
+static int do_proc_uint_conv_minmax(bool *negp, ulong *u_ptr, uint *k_ptr,
+				    int dir, const struct ctl_table *tbl)
 {
 	return proc_uint_conv(u_ptr, k_ptr, dir, tbl, true,
 			      proc_uint_u2k_conv, proc_uint_k2u_conv);
@@ -654,7 +654,7 @@ do_proc_dotypevec(ulong)
 
 static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
-			       int (*conv)(unsigned long *u_ptr,
+			       int (*conv)(bool *negp, unsigned long *u_ptr,
 					   unsigned int *k_ptr, int dir,
 					   const struct ctl_table *table))
 {
@@ -686,7 +686,7 @@ static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 		goto out_free;
 	}
 
-	if (conv(&lval, (unsigned int *) table->data, 1, table)) {
+	if (conv(&neg, &lval, (unsigned int *) table->data, 1, table)) {
 		err = -EINVAL;
 		goto out_free;
 	}
@@ -707,17 +707,18 @@ static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 
 static int do_proc_douintvec_r(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
-			       int (*conv)(unsigned long *u_ptr,
+			       int (*conv)(bool *negp, unsigned long *u_ptr,
 					   unsigned int *k_ptr, int dir,
 					   const struct ctl_table *table))
 {
 	unsigned long lval;
 	int err = 0;
 	size_t left;
+	bool negp;
 
 	left = *lenp;
 
-	if (conv(&lval, (unsigned int *) table->data, 0, table)) {
+	if (conv(&negp, &lval, (unsigned int *) table->data, 0, table)) {
 		err = -EINVAL;
 		goto out;
 	}
@@ -737,9 +738,8 @@ static int do_proc_douintvec_r(const struct ctl_table *table, void *buffer,
 
 static int do_proc_douintvec(const struct ctl_table *table, int dir,
 			     void *buffer, size_t *lenp, loff_t *ppos,
-			      int (*conv)(unsigned long *u_ptr,
-					  unsigned int *k_ptr, int dir,
-					  const struct ctl_table *table))
+			     int (*conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
+					 int dir, const struct ctl_table *table))
 {
 	unsigned int vleft;
 
@@ -760,9 +760,6 @@ static int do_proc_douintvec(const struct ctl_table *table, int dir,
 		return -EINVAL;
 	}
 
-	if (!conv)
-		conv = do_proc_uint_conv;
-
 	if (SYSCTL_USER_TO_KERN(dir))
 		return do_proc_douintvec_w(table, buffer, lenp, ppos, conv);
 	return do_proc_douintvec_r(table, buffer, lenp, ppos, conv);
@@ -786,9 +783,13 @@ static int do_proc_douintvec(const struct ctl_table *table, int dir,
  */
 int proc_douintvec_conv(const struct ctl_table *table, int dir, void *buffer,
 			size_t *lenp, loff_t *ppos,
-			int (*conv)(unsigned long *u_ptr, unsigned int *k_ptr,
+			int (*conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
 				    int dir, const struct ctl_table *table))
 {
+
+	if (!conv)
+		conv = do_proc_uint_conv;
+
 	return do_proc_douintvec(table, dir, buffer, lenp, ppos, conv);
 }
 
@@ -1332,7 +1333,7 @@ int proc_douintvec_minmax(const struct ctl_table *table, int dir,
 
 int proc_douintvec_conv(const struct ctl_table *table, int write, void *buffer,
 			size_t *lenp, loff_t *ppos,
-			int (*conv)(unsigned long *lvalp, unsigned int *valp,
+			int (*conv)(bool *negp, ulong *lvalp, uint *valp,
 				    int write, const struct ctl_table *table))
 {
 	return -ENOSYS;

-- 
2.50.1

