From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 13 Oct 2025 15:24:52 +0200
Subject: [PATCH 2/8] sysctl: Remove superfluous tbl_data param from "dovec"
 functions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251013-jag-sysctl_conv-v1-2-4dc35ceae733@kernel.org>
References: <20251013-jag-sysctl_conv-v1-0-4dc35ceae733@kernel.org>
In-Reply-To: <20251013-jag-sysctl_conv-v1-0-4dc35ceae733@kernel.org>
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=6367;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Yb7SCKMM9yyjHxvSmVCws0zzI54RVCOIkVV6fK8yIW8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjs/dPkczHhpnasOkJdj1xEHRrDVUE7lRQrG
 FGPm0A+4HVSO4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo7P3TAAoJELqXzVK3
 lkFPYBsL/RPScYsGMJU32qtKU5mXjKnko3sBib7y+rJ5pvSQ3UvnTtofkDDmLV1xPcmjup+7JlT
 WIPxFud+QRPxVVTZub2zLxuE+7c7EHRoDH+Y4GG/9L7oGhyiOsrRmuB7XcMQAyjf7kWQtXtlk+v
 9D8WJk+FsTk5RI62ntH5Vb8lsdblCoHv6KTGXKSOVBt5fHkh0RK9mwNKD01MuvcSpgZsZkNR3tZ
 new29VWrD4WsGtwQBVMABHXkHrFLHEvDt62GpyAO8i0M4EOQyFJJmuH2YAv2WGZ1X+vtqXteLsr
 42Yb06+AnrXhILQARfZKsTs2U4/AhVMnNhVzXu1UItnChvaTVlm3Mc5mWX3iQdPoif7GbSU1Z88
 2PAZ7wTpNnKx3K0uPlF4XuK+HJhCZxTw+wYT2SgkXwxGR0I6YKAskWDGsLS5itlcLMyH0D4hEGV
 rT/hPgr2wsQWASRZ5/NbR+A96oYFKvknqv7SC/mnMLdpUaEGvKV0FyfBuGCMIby+zaeKOSSh6R4
 +U=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove superfluous tbl_data param from do_proc_douintvec{,_r,_w}
and __do_proc_do{intvec,uintvec,ulongvec_minmax}. There is no need to
pass it as it is always contained within the ctl_table struct.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 61 ++++++++++++++++++++++++---------------------------------
 1 file changed, 26 insertions(+), 35 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index f0a691ffb29067a019a857a62fa56185aab06c61..0e249a1f99fec084db649782f5ef8b37e40c6a7c 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -398,22 +398,22 @@ static int do_proc_douintvec_conv(unsigned long *lvalp,
 
 static const char proc_wspace_sep[] = { ' ', '\t', '\n' };
 
-static int __do_proc_dointvec(void *tbl_data, const struct ctl_table *table,
-		  int write, void *buffer,
-		  size_t *lenp, loff_t *ppos,
-		  int (*conv)(bool *negp, unsigned long *lvalp, int *valp,
-			      int write, const struct ctl_table *table))
+static int __do_proc_dointvec(const struct ctl_table *table, int write,
+			      void *buffer, size_t *lenp, loff_t *ppos,
+			      int (*conv)(bool *negp, unsigned long *lvalp,
+					  int *valp, int write,
+					  const struct ctl_table *table))
 {
 	int *i, vleft, first = 1, err = 0;
 	size_t left;
 	char *p;
 
-	if (!tbl_data || !table->maxlen || !*lenp || (*ppos && !write)) {
+	if (!table->data || !table->maxlen || !*lenp || (*ppos && !write)) {
 		*lenp = 0;
 		return 0;
 	}
 
-	i = (int *) tbl_data;
+	i = (int *) table->data;
 	vleft = table->maxlen / sizeof(*i);
 	left = *lenp;
 
@@ -475,13 +475,10 @@ static int do_proc_dointvec(const struct ctl_table *table, int write,
 		  int (*conv)(bool *negp, unsigned long *lvalp, int *valp,
 			      int write, const struct ctl_table *table))
 {
-	return __do_proc_dointvec(table->data, table, write,
-			buffer, lenp, ppos, conv);
+	return __do_proc_dointvec(table, write, buffer, lenp, ppos, conv);
 }
 
-static int do_proc_douintvec_w(unsigned int *tbl_data,
-			       const struct ctl_table *table,
-			       void *buffer,
+static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
 			       int (*conv)(unsigned long *lvalp,
 					   unsigned int *valp, int write,
@@ -515,7 +512,7 @@ static int do_proc_douintvec_w(unsigned int *tbl_data,
 		goto out_free;
 	}
 
-	if (conv(&lval, tbl_data, 1, table)) {
+	if (conv(&lval, (unsigned int *) table->data, 1, table)) {
 		err = -EINVAL;
 		goto out_free;
 	}
@@ -535,8 +532,7 @@ static int do_proc_douintvec_w(unsigned int *tbl_data,
 	return err;
 }
 
-static int do_proc_douintvec_r(unsigned int *tbl_data,
-			       const struct ctl_table *table, void *buffer,
+static int do_proc_douintvec_r(const struct ctl_table *table, void *buffer,
 			       size_t *lenp, loff_t *ppos,
 			       int (*conv)(unsigned long *lvalp,
 					   unsigned int *valp, int write,
@@ -548,7 +544,7 @@ static int do_proc_douintvec_r(unsigned int *tbl_data,
 
 	left = *lenp;
 
-	if (conv(&lval, tbl_data, 0, table)) {
+	if (conv(&lval, (unsigned int *) table->data, 0, table)) {
 		err = -EINVAL;
 		goto out;
 	}
@@ -566,22 +562,20 @@ static int do_proc_douintvec_r(unsigned int *tbl_data,
 	return err;
 }
 
-static int __do_proc_douintvec(void *tbl_data, const struct ctl_table *table,
-			       int write, void *buffer,
-			       size_t *lenp, loff_t *ppos,
+static int __do_proc_douintvec(const struct ctl_table *table, int write,
+			       void *buffer, size_t *lenp, loff_t *ppos,
 			       int (*conv)(unsigned long *lvalp,
 					   unsigned int *valp, int write,
 					   const struct ctl_table *table))
 {
-	unsigned int *i, vleft;
+	unsigned int vleft;
 
-	if (!tbl_data || !table->maxlen || !*lenp || (*ppos && !write)) {
+	if (!table->data || !table->maxlen || !*lenp || (*ppos && !write)) {
 		*lenp = 0;
 		return 0;
 	}
 
-	i = (unsigned int *) tbl_data;
-	vleft = table->maxlen / sizeof(*i);
+	vleft = table->maxlen / sizeof(unsigned int);
 
 	/*
 	 * Arrays are not supported, keep this simple. *Do not* add
@@ -596,9 +590,8 @@ static int __do_proc_douintvec(void *tbl_data, const struct ctl_table *table,
 		conv = do_proc_douintvec_conv;
 
 	if (write)
-		return do_proc_douintvec_w(i, table, buffer, lenp, ppos,
-					   conv);
-	return do_proc_douintvec_r(i, table, buffer, lenp, ppos, conv);
+		return do_proc_douintvec_w(table, buffer, lenp, ppos, conv);
+	return do_proc_douintvec_r(table, buffer, lenp, ppos, conv);
 }
 
 int do_proc_douintvec(const struct ctl_table *table, int write,
@@ -607,8 +600,7 @@ int do_proc_douintvec(const struct ctl_table *table, int write,
 				  unsigned int *valp, int write,
 				  const struct ctl_table *table))
 {
-	return __do_proc_douintvec(table->data, table, write, buffer, lenp,
-				   ppos, conv);
+	return __do_proc_douintvec(table, write, buffer, lenp, ppos, conv);
 }
 
 /**
@@ -839,9 +831,8 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int write,
 }
 EXPORT_SYMBOL_GPL(proc_dou8vec_minmax);
 
-static int __do_proc_doulongvec_minmax(void *data,
-		const struct ctl_table *table, int write,
-		void *buffer, size_t *lenp, loff_t *ppos,
+static int __do_proc_doulongvec_minmax(const struct ctl_table *table,
+		int write, void *buffer, size_t *lenp, loff_t *ppos,
 		unsigned long convmul, unsigned long convdiv)
 {
 	unsigned long *i, *min, *max;
@@ -849,12 +840,12 @@ static int __do_proc_doulongvec_minmax(void *data,
 	size_t left;
 	char *p;
 
-	if (!data || !table->maxlen || !*lenp || (*ppos && !write)) {
+	if (!table->data || !table->maxlen || !*lenp || (*ppos && !write)) {
 		*lenp = 0;
 		return 0;
 	}
 
-	i = data;
+	i = table->data;
 	min = table->extra1;
 	max = table->extra2;
 	vleft = table->maxlen / sizeof(unsigned long);
@@ -917,8 +908,8 @@ static int do_proc_doulongvec_minmax(const struct ctl_table *table, int write,
 		void *buffer, size_t *lenp, loff_t *ppos, unsigned long convmul,
 		unsigned long convdiv)
 {
-	return __do_proc_doulongvec_minmax(table->data, table, write,
-			buffer, lenp, ppos, convmul, convdiv);
+	return __do_proc_doulongvec_minmax(table, write, buffer, lenp, ppos,
+					   convmul, convdiv);
 }
 
 /**

-- 
2.50.1

