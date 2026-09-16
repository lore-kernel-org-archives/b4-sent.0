From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 16 Sep 2026 13:44:28 +0200
Subject: [PATCH] sysctl: Use replace **void with **char in proc_put_*
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260916-lklm-sysctl-void-vs-char-v1-1-c3f8b2eb8b1e@kernel.org>
X-B4-Tracking: v=1; b=H4sIABuBqmoC/x2MSQqAMAwAvyI5G2itCPoV8VBr1GBdaKQo4t8tH
 gdm5gGhwCTQZA8Eiiy8bwl0noGb7TYR8pAYClVUqtYV+sWvKLe402PcecAomMyApbLK2t5oZwh
 SfgQa+frXbfe+H2t23+tqAAAA
X-Change-ID: 20260916-lklm-sysctl-void-vs-char-40a0aab31c3e
To: Kees Cook <kees@kernel.org>
Cc: Bradley Morgan <include@grrlz.net>, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4582;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=rHuOQJsSbNcWyIXumEYhyOj62sbaFMWxhmLQLcLgJ20=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGqqgR8g/8ZTQciO4Ksj436rep7Nxaa7l0YiU
 1n/p4mFw/QTa4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqqoEfAAoJELqXzVK3
 lkFPFDwL/Agqb8SN3vgqPEF5y/qFihkRi5QCNDO3AODhGcXggD/EPTlIybJP6jTyatgRws6INuU
 eFK7oquU3aE7xdwrXWb0h2GUGcgEWlLiDvzpqRshAxLf00pFGeJedLNCTzpA1Z3T9RDAKS8qOs7
 s/U0RfkEvyGDOspeTKlHkhYP6TIx5nu4sIU5MlvS6b5frA/57CXae3IPeB3NKOu6k+6+TsgrTbB
 UASK7YB1UMG4L9hM8DWP/hNQYl44c7hOlZd4ZBfyqa0xeKljH+atLKD6JImsx7dQTBAEzumgoIG
 mr/f4zs+Nx5LDqj/+9Bgx0MP5oO4CfskUuuQY8pBepA+D0IQWBkgssvOm5ERtcWPhTBelIVMrZ6
 nIWlo5B2S2xmaxtCavqj7CAQfhF6zOtyngdDvLdbOR4tORWeDqeyXvZ1hi+gtRKJw/wo4DPWahn
 yVNS6Hc5cApKDOUqWEWTZMEzKingebISJsbSJ1J2zPpGWr+8U6nFvDrq4wuOzOP1Ib4+JtBfiB7
 fc=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace **void argument with **char in the proc_put_* functions. These
are leftovers from before commit 32927393dc1c ("sysctl: pass kernel
pointers to ->proc_handler") where a cast to char __user** from void
_user** was needed before the put_user call.

Suggested-by: Bradley Morgan <include@grrlz.net>
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 34 +++++++++++++++-------------------
 1 file changed, 15 insertions(+), 19 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 25577ffc2801267cc69df60a1064ada9efd4b97d..1fefe18bf84e790433a1abf71a4b158f3c1f729f 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -332,7 +332,7 @@ static int proc_get_long(char **buf, size_t *size,
  * In case of success @buf and @size are updated with the amount of bytes
  * written.
  */
-static void proc_put_long(void **buf, size_t *size, unsigned long val, bool neg)
+static void proc_put_long(char **buf, size_t *size, unsigned long val, bool neg)
 {
 	int len;
 	char tmp[TMPBUFLEN], *p = tmp;
@@ -347,15 +347,12 @@ static void proc_put_long(void **buf, size_t *size, unsigned long val, bool neg)
 }
 #undef TMPBUFLEN
 
-static void proc_put_char(void **buf, size_t *size, char c)
+static void proc_put_char(char **buf, size_t *size, char c)
 {
 	if (*size) {
-		char **buffer = (char **)buf;
-		**buffer = c;
-
+		**buf = c;
 		(*size)--;
-		(*buffer)++;
-		*buf = *buffer;
+		(*buf)++;
 	}
 }
 
@@ -680,12 +677,12 @@ static int apply_conv_on_vec(const union proc_vec_conv conv,
 			     const struct ctl_table *table,
 			     const enum proc_vec_type data_type,
 			     const size_t data_size, const int conv_dir,
-			     const size_t buf_nbyte, void *buf,
+			     const size_t buf_nbyte, char *buf,
 			     size_t *buf_left_final)
 {
 	int vec_left, err = 0;
 	size_t buf_left, nr_conv = 0;
-	char *data, *data_stage = NULL, *p;
+	char *data, *data_stage = NULL;
 	bool is_unsigned = data_type == PROC_VEC_UINT || data_type == PROC_VEC_ULONG;
 
 	buf_left = buf_nbyte;
@@ -694,7 +691,6 @@ static int apply_conv_on_vec(const union proc_vec_conv conv,
 	if (SYSCTL_USER_TO_KERN(conv_dir)) {
 		if (buf_left > PAGE_SIZE - 1)
 			buf_left = PAGE_SIZE - 1;
-		p = buf;
 
 		if (table->maxlen > data_size) {
 			data_stage = kmemdup(table->data, table->maxlen, GFP_KERNEL);
@@ -712,11 +708,11 @@ static int apply_conv_on_vec(const union proc_vec_conv conv,
 		bool neg = false;
 
 		if (SYSCTL_USER_TO_KERN(conv_dir)) {
-			proc_skip_spaces(&p, &buf_left);
+			proc_skip_spaces(&buf, &buf_left);
 
 			if (!buf_left)
 				break;
-			err = proc_get_long(&p, &buf_left, &lval, &neg,
+			err = proc_get_long(&buf, &buf_left, &lval, &neg,
 					    proc_wspace_sep,
 					    sizeof(proc_wspace_sep), NULL);
 			if (!err && neg && is_unsigned)
@@ -740,7 +736,7 @@ static int apply_conv_on_vec(const union proc_vec_conv conv,
 
 	if (SYSCTL_USER_TO_KERN(conv_dir)) {
 		if (!err && buf_left)
-			proc_skip_spaces(&p, &buf_left);
+			proc_skip_spaces(&buf, &buf_left);
 		if (!nr_conv) {
 			err = err ? : -EINVAL;
 			goto out;
@@ -1221,6 +1217,7 @@ int proc_do_large_bitmap(const struct ctl_table *table, int dir,
 	unsigned long *bitmap = *(unsigned long **) table->data;
 	unsigned long *tmp_bitmap = NULL;
 	char tr_a[] = { '-', ',', '\n' }, tr_b[] = { ',', '\n', 0 }, c = 0;
+	char *p = buffer;
 
 	if (!bitmap || !bitmap_len || !left || (*ppos && SYSCTL_KERN_TO_USER(dir))) {
 		*lenp = 0;
@@ -1228,7 +1225,6 @@ int proc_do_large_bitmap(const struct ctl_table *table, int dir,
 	}
 
 	if (SYSCTL_USER_TO_KERN(dir)) {
-		char *p = buffer;
 		size_t skipped = 0;
 
 		if (left > PAGE_SIZE - 1) {
@@ -1315,16 +1311,16 @@ int proc_do_large_bitmap(const struct ctl_table *table, int dir,
 						   bit_a + 1) - 1;
 
 			if (!first)
-				proc_put_char(&buffer, &left, ',');
-			proc_put_long(&buffer, &left, bit_a, false);
+				proc_put_char(&p, &left, ',');
+			proc_put_long(&p, &left, bit_a, false);
 			if (bit_a != bit_b) {
-				proc_put_char(&buffer, &left, '-');
-				proc_put_long(&buffer, &left, bit_b, false);
+				proc_put_char(&p, &left, '-');
+				proc_put_long(&p, &left, bit_b, false);
 			}
 
 			first = 0; bit_b++;
 		}
-		proc_put_char(&buffer, &left, '\n');
+		proc_put_char(&p, &left, '\n');
 	}
 
 	if (!err) {

---
base-commit: 99156fbf3562bed74aa57d93b0b3eeec7c7f1ca6
change-id: 20260916-lklm-sysctl-void-vs-char-40a0aab31c3e

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

