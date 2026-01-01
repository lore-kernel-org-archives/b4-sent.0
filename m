From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 01 Jan 2026 13:57:09 +0100
Subject: [PATCH v2 5/9] sysctl: Generate do_proc_douintvec with a
 type-generic macro
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-jag-dovec_consolidate-v2-5-ff918f753ba9@kernel.org>
References: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
In-Reply-To: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3960;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=DoeOUcfzBiDemYNQ6HSUnBzBoU1D+S+RU5qQ3unL1OE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlWbyyE/WewKrBIth60d6n12M+u4EPc/LR75
 B2+D4kcqkE2HokBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpVm8sAAoJELqXzVK3
 lkFP3a8L/0C/D4LGj2mVPk0AbEsW6y30apYmMJKNFpm3EHkwLZ+52I4siB6o9XjhWP6wJft+P/F
 GoL2ZqVkI1IQ3712BJDhpjOpSGtlN8uXgwF3aGG8k6f1qHJvowrXxKwoxYBpfWdj1dCrwSSAud2
 qII6NkL0xhSXCOBmg4ihljummrYghwezSDt19DxXw9GwVTkDZkCmOucuJ+06F5eBWaE67kMBmns
 zZeFCszDMUX2XFhZd5ddo+t1gkL3d0QrUqkFBnFTpz9A6v6OXR8iDCA2YwKOH7BClBGoS/9MyrV
 eHJhePRCZ57fKfl6oIEbv0OPDnmAhEyeNPc/8uPb/fFamc3PELHRaqMXXkpnkfPlAr9CJVrkiUf
 vffqXAWm5cBK0Jcjt8cPs3Pvz+ZJoYd08hTDpmHI3/Odpnq5+qHndXt10xUCcWV+MS7K7YRDXSK
 usGRtcm8faSwqWonxSIH5NeYcNiGe9/6AMI/ROJxEA6RLTcQ3J75DfZtuosh/4/HHfHy+1OxIU6
 Nc=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Generate the behavior in do_proc_douintvec{,_w,_r} functions with
do_proc_dotypevec(uint). The originals (do_proc_douintvec{,_w,_r})
where created in the same way as do_proc_dotypevec but for individual
values (no vectors). In this commit we use the existing macro
implementation to extend do_proc_douintvec to include vectors of values.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 118 ++------------------------------------------------------
 1 file changed, 3 insertions(+), 115 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 8c0bbb82cfcbc8830a0f3a68326c002ac51d41a6..5bc1bd3d415be2552f085111852f63ddefb05894 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -451,8 +451,8 @@ static int do_proc_uint_conv(bool *negp, ulong *u_ptr, uint *k_ptr, int dir,
 			      proc_uint_u2k_conv, proc_uint_k2u_conv);
 }
 
-static int do_proc_uint_conv_minmax(ulong *u_ptr, uint *k_ptr, int dir,
-				    const struct ctl_table *tbl)
+static int do_proc_uint_conv_minmax(bool *negp, ulong *u_ptr, uint *k_ptr,
+				    int dir, const struct ctl_table *tbl)
 {
 	return proc_uint_conv(u_ptr, k_ptr, dir, tbl, true,
 			      proc_uint_u2k_conv, proc_uint_k2u_conv);
@@ -651,119 +651,7 @@ out: \
 
 do_proc_dotypevec(int)
 do_proc_dotypevec(ulong)
-
-static int do_proc_douintvec_w(const struct ctl_table *table, void *buffer,
-			       size_t *lenp, loff_t *ppos,
-			       int (*conv)(bool *negp, unsigned long *u_ptr,
-					   unsigned int *k_ptr, int dir,
-					   const struct ctl_table *table))
-{
-	unsigned long lval;
-	int err = 0;
-	size_t left;
-	bool neg;
-	char *p = buffer;
-
-	left = *lenp;
-
-	if (proc_first_pos_non_zero_ignore(ppos, table))
-		goto bail_early;
-
-	if (left > PAGE_SIZE - 1)
-		left = PAGE_SIZE - 1;
-
-	proc_skip_spaces(&p, &left);
-	if (!left) {
-		err = -EINVAL;
-		goto out_free;
-	}
-
-	err = proc_get_long(&p, &left, &lval, &neg,
-			     proc_wspace_sep,
-			     sizeof(proc_wspace_sep), NULL);
-	if (err || neg) {
-		err = -EINVAL;
-		goto out_free;
-	}
-
-	if (conv(&lval, (unsigned int *) table->data, 1, table)) {
-		err = -EINVAL;
-		goto out_free;
-	}
-
-	if (!err && left)
-		proc_skip_spaces(&p, &left);
-
-out_free:
-	if (err)
-		return -EINVAL;
-
-	return 0;
-
-bail_early:
-	*ppos += *lenp;
-	return err;
-}
-
-static int do_proc_douintvec_r(const struct ctl_table *table, void *buffer,
-			       size_t *lenp, loff_t *ppos,
-			       int (*conv)(bool *negp, unsigned long *u_ptr,
-					   unsigned int *k_ptr, int dir,
-					   const struct ctl_table *table))
-{
-	unsigned long lval;
-	int err = 0;
-	size_t left;
-	bool negp;
-
-	left = *lenp;
-
-	if (conv(&negp, &lval, (unsigned int *) table->data, 0, table)) {
-		err = -EINVAL;
-		goto out;
-	}
-
-	proc_put_long(&buffer, &left, lval, false);
-	if (!left)
-		goto out;
-
-	proc_put_char(&buffer, &left, '\n');
-
-out:
-	*lenp -= left;
-	*ppos += *lenp;
-
-	return err;
-}
-
-static int do_proc_douintvec(const struct ctl_table *table, int dir,
-			     void *buffer, size_t *lenp, loff_t *ppos,
-			     int (*conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
-					 int dir, const struct ctl_table *table))
-{
-	unsigned int vleft;
-
-	if (!table->data || !table->maxlen || !*lenp ||
-	    (*ppos && SYSCTL_KERN_TO_USER(dir))) {
-		*lenp = 0;
-		return 0;
-	}
-
-	vleft = table->maxlen / sizeof(unsigned int);
-
-	/*
-	 * Arrays are not supported, keep this simple. *Do not* add
-	 * support for them.
-	 */
-	if (vleft != 1) {
-		*lenp = 0;
-		return -EINVAL;
-	}
-
-	if (SYSCTL_USER_TO_KERN(dir))
-		return do_proc_douintvec_w(table, buffer, lenp, ppos, conv);
-	return do_proc_douintvec_r(table, buffer, lenp, ppos, conv);
-}
+do_proc_dotypevec(uint)
 
 /**
  * proc_douintvec_conv - read a vector of unsigned ints with a custom converter

-- 
2.50.1

