From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 14 Aug 2026 12:41:13 +0200
Subject: [PATCH v2 2/4] sysctl: Reject uint arrays before calling the
 general proc_vec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-lklm-partial_ctlvec-v2-2-9df50d26e477@kernel.org>
References: <20260814-lklm-partial_ctlvec-v2-0-9df50d26e477@kernel.org>
In-Reply-To: <20260814-lklm-partial_ctlvec-v2-0-9df50d26e477@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: Jianlin Shi <shijianlin11@foxmail.com>, akpm@linux-foundation.org, 
 vbabka@kernel.org, hannes@cmpxchg.org, surenb@google.com, mhocko@suse.com, 
 jackmanb@google.com, ziy@nvidia.com, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-mm@kvack.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2851;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=ACmHDzg0bdqhRKtZiggZe9yyDKsjLpeE7LXC/BUIylE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGp+8NDu6mELinrd4Zbsp71ht/npxGd5//lUz
 p/ms+oZ3YkI2okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqfvDQAAoJELqXzVK3
 lkFPOlcL/A582yimDhlcHkvz9SG0STpA5Qs3yhtyNi7XgDJdTE3l5T8et6PDFryntBnyzN/h2Kb
 NQ8Bm1TNmZLmNrZj/NQxdhp9obZAgFaePZAb6h6SKmZjZls60bDttBqmoufK+lz/qhD2tFpDYgV
 yM5RWJxWi3BZLDP9Fkxhw8ApM4bs+B9BC2DshT1jveym+shgHuts1D+sBhnH4RdWucKgvFl6Q7u
 mrbpywg0cl1GHRhe6ZwasXkLgrwUJs5oRw0cVCop4SqzLWipln452fskR6/WpF1p8YsmPT2s9ZN
 0jIS9/MI/aMXGFbfTo7wYZ5V7J6jj6Rg58gxXnKf2g7S/Q+Fi6deXQy0/izZ46RO2Qc9PC/bUWT
 KWz8Ysec+jRY7bSr8F5GZnSRVO5bZuOJW7YJtIMLiKU2rGq2ZTaK6TnMg17q0N3Kc//OJzGADvf
 pgMhe6EVetnBHd2ffgh9b3c6rM4wkI3X1GJAmzv1BsNxbsPWo5YTXWC6NSogE++M/IHTarsIUi9
 ak=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the UINT vector size check to proc_douintvec_conv; the function
that routes UINT types only. Route all the UINT calls (including
proc_dou8vec_minmax) through proc_douintvec_conv.

UINT proc handlers that incorrectly define maxlen will now return
-EINVAL instead of 0 in the cases where data is missing, lenp is 0 or
ppos is 0. Note that maxlen == 0 is not considered as miss-defined.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 17 +++++++----------
 1 file changed, 7 insertions(+), 10 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 47a92cbbcb69cd361a18dba6606ae6ae8f86b5e2..7e9024899be6d5971752dd5639ab4b806a899081 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -748,10 +748,6 @@ static int proc_vec(const struct ctl_table *table, int dir, void *buffer,
 		return 0;
 	}
 
-	/* uint arrays are not supported, *Do not* add support for them. */
-	if (type == PROC_VEC_UINT && (table->maxlen / data_size) != 1)
-		return -EINVAL;
-
 	if (SYSCTL_USER_TO_KERN(dir)) {
 		if (proc_first_pos_non_zero_ignore(ppos, table))
 			goto out;
@@ -797,6 +793,9 @@ int proc_douintvec_conv(const struct ctl_table *table, int dir, void *buffer,
 			int (*conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
 				    int dir, const struct ctl_table *table))
 {
+	/* uint arrays are not supported, *Do not* add support for them. */
+	if (table->maxlen && (table->maxlen / sizeof(uint)) != 1)
+		return -EINVAL;
 
 	if (!conv)
 		conv = do_proc_uint_conv;
@@ -881,8 +880,7 @@ int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 		size_t *lenp, loff_t *ppos)
 {
-	return proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
-			(union proc_vec_conv){ .uint_conv = do_proc_uint_conv });
+	return proc_douintvec_conv(table, dir, buffer, lenp, ppos, do_proc_uint_conv);
 }
 
 /**
@@ -932,8 +930,8 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 int proc_douintvec_minmax(const struct ctl_table *table, int dir,
 			  void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
-			(union proc_vec_conv){ .uint_conv = do_proc_uint_conv_minmax });
+	return proc_douintvec_conv(table, dir, buffer, lenp, ppos,
+				   do_proc_uint_conv_minmax);
 }
 
 /**
@@ -976,8 +974,7 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int dir,
 		tmp.extra2 = (unsigned int *) &max;
 
 	val = READ_ONCE(*data);
-	res = proc_vec(&tmp, dir, buffer, lenp, ppos, PROC_VEC_UINT,
-		       (union proc_vec_conv){ .uint_conv = do_proc_uint_conv_minmax });
+	res = proc_douintvec_minmax(&tmp, dir, buffer, lenp, ppos);
 	if (res)
 		return res;
 	if (SYSCTL_USER_TO_KERN(dir))

-- 
2.50.1

