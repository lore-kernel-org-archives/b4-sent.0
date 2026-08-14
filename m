From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 14 Aug 2026 12:41:14 +0200
Subject: [PATCH v2 3/4] sysctl: Disallow partial updates for erroneous
 sysctl vectors
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260814-lklm-partial_ctlvec-v2-3-9df50d26e477@kernel.org>
References: <20260814-lklm-partial_ctlvec-v2-0-9df50d26e477@kernel.org>
In-Reply-To: <20260814-lklm-partial_ctlvec-v2-0-9df50d26e477@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>
Cc: Jianlin Shi <shijianlin11@foxmail.com>, akpm@linux-foundation.org, 
 vbabka@kernel.org, hannes@cmpxchg.org, surenb@google.com, mhocko@suse.com, 
 jackmanb@google.com, ziy@nvidia.com, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-mm@kvack.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4178;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=CJlMe8eckMtRbFMo6OjTUfLXAWdcwp7d+38BdYAigIE=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGp+8NHUjrC7/UY5qTi0oMM3LIpSbQYbXCUtz
 uIVIOsjNamHHIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqfvDRAAoJELqXzVK3
 lkFPMgUL/1+0vc9a7WaBT4uQrdf6jczPCFm0E/iBcZQPHgbAfV+CEAmg0uJf2GHtzgs9xmRKM6E
 HxBTtxcUx5A/LhJWwVQberzSHPAf1BaKBa5ymaidcfZNBCG0TEn5hVChTZqPHT8m5frNEYt4JQu
 Ao5xgFF2wgHM4ExTr5rB1xccWG8AF+FRZI+YcR747VuBx2BUd70cOmQeTrxSyoITjkOVzL9Ad6Y
 0owmDRcqrx3GJRa8xcK0CCuw9nLGB53pQfkAJhBTkD+B9OKgf6CmgHLLJsUqreQzPsRJsxR7f2k
 PKXfYS7UZTBKMrKouFiXKAjAiX49LXafoFkwGzwrsFIfBeliqQPkw+YFHmxfbJnHvCawt37SPdM
 x1qVyHmVRqzyp73hHuxn3IGLUBsjURiyVRGNdAHyRMnwm+pnL1NoZI/vNGRUg3qVXKOo5C4Xcn7
 EOPhbwbV3bTl7u+SWBFdqsthVkyw0VGeOE2sGm6a/4+oG/3YeolYydFWmyZnrtKnghQE32o11K4
 2M=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When updating the kernel sysctl vectors there is a chance that not all
vector elements are updated due to erroneous input. Use a staging
variable that holds a copy of the vector and commits to the actual
table->data only when all input is successfully updated.

The staging is only for vectors; cases where table->data points to a
variable should not be staged as they will not be updated on input
error. PROC_VEC_UINT is not included because UINT arrays are not
allowed.

Replace first with nr_conv, incremented where first was cleared. first
is exactly nr_conv == 0, and the counter doubles as the number of
elements to publish.

Example of behavior that is being prevented:

  # echo "4 4 1 7" > /proc/sys/kernel/printk
  # echo "1 x" > /proc/sys/kernel/printk
  -bash: echo: write error: Invalid argument
  # cat /proc/sys/kernel/printk
  1 4 1 7 <- incorrect

It should be unchanged ("4 4 1 7") on error.

Link: https://lore.kernel.org/all/tencent_A860C873956A52E26AD8D309A308A241BA08@qq.com/
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 65 +++++++++++++++++++++++++++++++++++++++++++++------------
 1 file changed, 52 insertions(+), 13 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 7e9024899be6d5971752dd5639ab4b806a899081..25577ffc2801267cc69df60a1064ada9efd4b97d 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -637,6 +637,26 @@ static int proc_vec_conv(enum proc_vec_type type, union proc_vec_conv conv,
 	return -EINVAL;
 }
 
+static int commit_conv_vec(const enum proc_vec_type data_type, void *dst,
+			    const void *src, size_t nr)
+{
+	size_t i;
+
+	switch (data_type) {
+	case PROC_VEC_INT:
+		for (i = 0; i < nr; i++)
+			WRITE_ONCE(((int *)dst)[i], ((const int *)src)[i]);
+		return 0;
+
+	case PROC_VEC_ULONG:
+		for (i = 0; i < nr; i++)
+			WRITE_ONCE(((ulong *)dst)[i], ((const ulong *)src)[i]);
+		return 0;
+	default:
+		return -EINVAL;
+	}
+}
+
 /**
  * apply_conv_on_vec - Apply converter function on data vector
  *
@@ -663,22 +683,31 @@ static int apply_conv_on_vec(const union proc_vec_conv conv,
 			     const size_t buf_nbyte, void *buf,
 			     size_t *buf_left_final)
 {
-	int vec_left, first = 1, err = 0;
-	size_t buf_left;
-	char *data, *p;
+	int vec_left, err = 0;
+	size_t buf_left, nr_conv = 0;
+	char *data, *data_stage = NULL, *p;
 	bool is_unsigned = data_type == PROC_VEC_UINT || data_type == PROC_VEC_ULONG;
 
-	data = table->data;
-	vec_left = table->maxlen / data_size;
 	buf_left = buf_nbyte;
 
+	data = table->data;
 	if (SYSCTL_USER_TO_KERN(conv_dir)) {
 		if (buf_left > PAGE_SIZE - 1)
 			buf_left = PAGE_SIZE - 1;
 		p = buf;
+
+		if (table->maxlen > data_size) {
+			data_stage = kmemdup(table->data, table->maxlen, GFP_KERNEL);
+			if (!data_stage) {
+				err = -ENOMEM;
+				goto out;
+			}
+			data = data_stage;
+		}
 	}
 
-	for (; buf_left && vec_left--; data += data_size, first = 0) {
+	vec_left = table->maxlen / data_size;
+	for (; buf_left && vec_left--; data += data_size, nr_conv++) {
 		unsigned long lval;
 		bool neg = false;
 
@@ -703,20 +732,30 @@ static int apply_conv_on_vec(const union proc_vec_conv conv,
 				err = -EINVAL;
 				break;
 			}
-			if (!first)
+			if (nr_conv)
 				proc_put_char(&buf, &buf_left, '\t');
 			proc_put_long(&buf, &buf_left, lval, neg);
 		}
 	}
 
-	if (SYSCTL_KERN_TO_USER(conv_dir) && !first && buf_left && !err)
-		proc_put_char(&buf, &buf_left, '\n');
-	if (SYSCTL_USER_TO_KERN(conv_dir) && !err && buf_left)
-		proc_skip_spaces(&p, &buf_left);
-	if (SYSCTL_USER_TO_KERN(conv_dir) && first)
-		return err ? : -EINVAL;
+	if (SYSCTL_USER_TO_KERN(conv_dir)) {
+		if (!err && buf_left)
+			proc_skip_spaces(&p, &buf_left);
+		if (!nr_conv) {
+			err = err ? : -EINVAL;
+			goto out;
+		}
+		if (!err && data_stage)
+			err = commit_conv_vec(data_type, table->data, data_stage, nr_conv);
+	} else {
+		if (nr_conv && buf_left && !err)
+			proc_put_char(&buf, &buf_left, '\n');
+	}
+
 	*buf_left_final = buf_left;
 
+out:
+	kfree(data_stage);
 	return err;
 }
 

-- 
2.50.1

