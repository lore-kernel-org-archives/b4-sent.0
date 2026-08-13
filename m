From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 13 Aug 2026 14:18:38 +0200
Subject: [PATCH 2/4] sysctl: Reject uint arrays before calling the general
 proc_vec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260813-lklm-partial_ctlvec-v1-2-df9e51c13704@kernel.org>
References: <20260813-lklm-partial_ctlvec-v1-0-df9e51c13704@kernel.org>
In-Reply-To: <20260813-lklm-partial_ctlvec-v1-0-df9e51c13704@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 linux-mm@kvack.org
Cc: Jianlin Shi <shijianlin11@foxmail.com>, akpm@linux-foundation.org, 
 vbabka@kernel.org, hannes@cmpxchg.org, surenb@google.com, mhocko@suse.com, 
 jackmanb@google.com, ziy@nvidia.com, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2851;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=yv5GjkliXQcT8cxSUVRpuQJjqp7Lbh33VFnF+Gh4c50=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGp9tievBOA8miXa3XTlhlLBnnybuWYQGNvc0
 nRW5nZVG3g0RYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqfbYnAAoJELqXzVK3
 lkFPWHgL/3GOSaXYdmehuwFyZyAqE0pIMfSa1A0ISRSPCn80Dm1XIZm1UJz+XrXAaYqjqbSVbYW
 mDb1Ukt/LYEaKpoqJqu3I10CKPMQObYQrXuWZuSHYfZ6t/jSZhjC5gf9tfberLK2Secv7/3UrWA
 WH1/ot+xDko9X8ldQxC4xNjuJT9ItUriOdvmeWuvZ7LXTAxspY7kZLZkOD3B2RLKhnDBmsgWJeB
 h1gvq5wBnVS0BCAEMEIRAUy9WyGZ4aM0K7zygMTmucBsOvaeHGVIIeFwglgUImcxtbiGD2W5E4v
 QPDTxy9xLWi5OAMFFqUrSHZCsEX3ZsxBIZ2dL7tH5wQ6ccXfPGSYmTQXv+LassO+RUGJ9Zj6p1N
 gWsnm5FlrpPLimv6MDfpvvNYT8oR0gn9AeZ4iq2UayFCBGSBvNu+PhPDvNW1AuW8OdlqvK2dUx+
 eiUf2cUTD4IM3a2vyeTdhBaqE0N+s2Dh5xBXdVsteIc1eEmdJA3uP5mRyHlPCXbZrJRlcs+Su87
 Uo=
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
index ed0e5101949c2fa56e33d543c65175d0ab579fc7..c5fa916e626a336c004d596f4c74f829b1cdc5e1 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -739,10 +739,6 @@ static int proc_vec(const struct ctl_table *table, int dir, void *buffer,
 		return 0;
 	}
 
-	/* uint arrays are not supported, *Do not* add support for them. */
-	if (type == PROC_VEC_UINT && (table->maxlen / data_size) != 1)
-		return -EINVAL;
-
 	if (SYSCTL_USER_TO_KERN(dir)) {
 		if (proc_first_pos_non_zero_ignore(ppos, table))
 			goto out;
@@ -788,6 +784,9 @@ int proc_douintvec_conv(const struct ctl_table *table, int dir, void *buffer,
 			int (*conv)(bool *negp, ulong *u_ptr, uint *k_ptr,
 				    int dir, const struct ctl_table *table))
 {
+	/* uint arrays are not supported, *Do not* add support for them. */
+	if (table->maxlen && (table->maxlen / sizeof(uint)) != 1)
+		return -EINVAL;
 
 	if (!conv)
 		conv = do_proc_uint_conv;
@@ -872,8 +871,7 @@ int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 int proc_douintvec(const struct ctl_table *table, int dir, void *buffer,
 		size_t *lenp, loff_t *ppos)
 {
-	return proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
-			(union proc_vec_conv){ .uint_conv = do_proc_uint_conv });
+	return proc_douintvec_conv(table, dir, buffer, lenp, ppos, do_proc_uint_conv);
 }
 
 /**
@@ -923,8 +921,8 @@ int proc_dointvec_minmax(const struct ctl_table *table, int dir,
 int proc_douintvec_minmax(const struct ctl_table *table, int dir,
 			  void *buffer, size_t *lenp, loff_t *ppos)
 {
-	return proc_vec(table, dir, buffer, lenp, ppos, PROC_VEC_UINT,
-			(union proc_vec_conv){ .uint_conv = do_proc_uint_conv_minmax });
+	return proc_douintvec_conv(table, dir, buffer, lenp, ppos,
+				   do_proc_uint_conv_minmax);
 }
 
 /**
@@ -967,8 +965,7 @@ int proc_dou8vec_minmax(const struct ctl_table *table, int dir,
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

