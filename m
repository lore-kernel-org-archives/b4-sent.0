From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 15 Dec 2025 16:52:58 +0100
Subject: [PATCH] sysctl: Add missing kernel-doc for proc_dointvec_conv
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251215-jag-sysctl-doc-v1-1-2099a2dcd894@kernel.org>
X-B4-Tracking: v=1; b=H4sIANkuQGkC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDI0NT3azEdN3iyuLkkhzdlPxk3RTj5CTTpBRDEzNLSyWgpoKi1LTMCrC
 B0bG1tQCzwredYAAAAA==
X-Change-ID: 20251215-jag-sysctl-doc-d3cb5bd14699
To: Kees Cook <kees@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1504;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=VcO7f0f3cXa0FqqirX5IIydQhcsrKaS4ABTZrgP1kuk=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlALtyXDqaqBtEPoxduLEil1bMKjXvp/3ryv
 P1I42OuFU8a3okBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQC7cAAoJELqXzVK3
 lkFPbhUMAIUSCj7MTbSsvZKpRl2gjfsyUusMZIhcJyb+OpL9kHyzqqXPvOHtGJbZ8Z8KQroSP/j
 JFmoQ2F70IxzZHs243SZTydeoyhTTIX0s+32dWqZi579UE7AXrL2kUf/2Wjoe9IFqCOQBHMv7AL
 +94dr1WJ8y5QgfNdZdVFXZtM7pmbHB4qjSUbTIUo9MtAQ9RTM4W2E2G27dmghytkJzSGsSkwwU3
 07PjnKaUonerZBnBgEUU8B0hxTAVUfoe1oopbdktvzW8A2lG5Hljm/eccHBWrwK4tyLRzLTrr/8
 ZzVgXoIi9tQQvkCg5x5ssT7M66YqD22xXJ9WkrIGMqIEAxwJkkVbFokbiVUnlWvVZRt4nQ/qiEe
 GmMIloX/dm7y9BE+fLPPmnu86f3XTc763aPPQtEUOvO9+aV+W/xywduHB4FdlLAgE9GLEXc3/q9
 MM3z2XzWXoZPeVoZIDG0+au66QbfEM6IF2TUskMR4fNnKQLJ25GBORIklZU84mDvqRmLOJPpbE6
 Zk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add kernel-doc documentation for the proc_dointvec_conv function to
describe its parameters and return value.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 2cd767b9680eb696efeae06f436548777b1b6844..b589f50d62854985c4c063232c95bd7590434738 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -862,6 +862,22 @@ int proc_doulongvec_minmax(const struct ctl_table *table, int dir,
 	return proc_doulongvec_minmax_conv(table, dir, buffer, lenp, ppos, 1l, 1l);
 }
 
+/**
+ * proc_dointvec_conv - read a vector of ints with a custom converter
+ * @table: the sysctl table
+ * @dir: %TRUE if this is a write to the sysctl file
+ * @buffer: the user buffer
+ * @lenp: the size of the user buffer
+ * @ppos: file position
+ * @conv: Custom converter call back
+ *
+ * Reads/writes up to table->maxlen/sizeof(unsigned int) unsigned integer
+ * values from/to the user buffer, treated as an ASCII string. Negative
+ * strings are not allowed.
+ *
+ * Returns 0 on success
+ */
+
 int proc_dointvec_conv(const struct ctl_table *table, int dir, void *buffer,
 		       size_t *lenp, loff_t *ppos,
 		       int (*conv)(bool *negp, unsigned long *u_ptr, int *k_ptr,

---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251215-jag-sysctl-doc-d3cb5bd14699

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

