From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 17 Dec 2025 09:04:39 +0100
Subject: [PATCH 1/7] sysctl: Return -ENOSYS from proc_douintvec_conv when
 CONFIG_PROC_SYSCTL=n
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251217-jag-no-macro-conv-v1-1-6e4252687915@kernel.org>
References: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
In-Reply-To: <20251217-jag-no-macro-conv-v1-0-6e4252687915@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=928;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=ONjskDJSnMc2NvXpXHulyVNB4siKX2n/8tf9NPapg1M=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlCZEnD3wipew55YC8O32lYsa+eP0IUJsDCH
 472Y7oCRrOCu4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpQmRJAAoJELqXzVK3
 lkFPPaQL/A4Smb3BpiMugKxIpE6/bf9WqLUYniX/SQ/1PIyHP8+oUDg9sAu4LzybYpfqrxoaqhF
 rH9CKy+7RQizNZdj+/tXEKko7aka2URX4t6/4R1WVMQIv6WVuHhwznxSHf+UuiN5nC/5dIp5XVB
 PylQUfhKyx3Sygufu4x4wj5IVgJTf1ve8hyxrHWbM5ZfyAT/aYOVJr3pr+Ly9++XYDFJBUHipKo
 A5Jq2gwFStCKQPSPv26rBd4IiKAM2ivDQRcLEHwb7c1rGCuBVao9u8EE7sJQ74gnDrvn31RwAs2
 UIjeaeGmkOq7bK0mKKHDTDk17HKJaS9uL373t0vz/X35noRWrzzKjMbUrXkJ9zSzuPW2ncmJ7Zv
 TpC5E4VFjQh4dGkbjKFA3zrugebeXiv+XAmLL8PBtQAzyvz9sDotq/6fW9E/GzJWGVBtefPS4hR
 czbcYP/tZYlQtKJR+w1o+u2GPsj0aKH575bxgureyIhOiSIccuLdOPkfEKpWfkCLEPsqMUXJfG5
 d0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Ensure an error if prco_douintvec_conv is erroneously called in a system
with CONFIG_PROC_SYSCTL=n

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 2cd767b9680eb696efeae06f436548777b1b6844..84ca24fb1965e97dc9e6f71f42a6c99c01aca3ee 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1055,6 +1055,14 @@ int proc_douintvec_minmax(const struct ctl_table *table, int dir,
 	return -ENOSYS;
 }
 
+int proc_douintvec_conv(const struct ctl_table *table, int write, void *buffer,
+			size_t *lenp, loff_t *ppos,
+			int (*conv)(unsigned long *lvalp, unsigned int *valp,
+				    int write, const struct ctl_table *table))
+{
+	return -ENOSYS;
+}
+
 int proc_dou8vec_minmax(const struct ctl_table *table, int dir,
 			void *buffer, size_t *lenp, loff_t *ppos)
 {

-- 
2.50.1

