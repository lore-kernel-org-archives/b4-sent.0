From: Joel Granados <joel.granados@kernel.org>
Date: Wed, 24 Dec 2025 17:55:51 +0100
Subject: [PATCH v4] loadpin: Implement custom proc_handler for enforce
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251224-jag-const_loadpin-v4-1-258afd70d2ce@kernel.org>
X-B4-Tracking: v=1; b=H4sIABYbTGkC/33OTQ6CMBAF4KuQrq1ph/6IK+9hjCnQQpW0pCVEQ
 7i7hRVR4vJNMt97E4o6WB3ROZtQ0KON1rsU2CFDVatco7GtU0ZAgFOgHD9Ugyvv4nDvvKp767A
 U1BAORoqKofTXB23sazWvt5RbGwcf3mvFSJfrP22kmGJxYiAlN0wX5PLUwenu6EODFm6ELVHsE
 ZAIRVlBVJlzResfIt8QAHtEvqxgIq8YI6b8WjHP8wfuLKpJOQEAAA==
X-Change-ID: 20251215-jag-const_loadpin-761f052f76c4
To: Kees Cook <kees@kernel.org>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-security-module@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4378;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=b0C1BTPdHoSx63Pm9jPRF5o3RI5jfer9NQ/R8Yf8t0A=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlMGye71vea988RF/nVJyzZlKHX6ugFZRjJg
 ZnHSNbAfKqqAYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpTBsnAAoJELqXzVK3
 lkFPqG4MAIdbPZjNAGKSk8HFdDUB9ELzFoePIk9jyypcPeWBykIjOmFLAQeYNglq9fMUHc1KjHA
 D0n88rnwgnEIXKJSL2bbuIOY1gpUG32GmHhUn5rScEeJvzWMoPCEiO1Yosv2BMjEuLZIngEBvzJ
 NS3N8EszgVqJTZPoJLNnQRXpGqyJO05ZfBin4XzdQ927pdKxFHw6yBd1ny4wFSHxUXozv5WSAQo
 KOnNttoGXSWBb+OC3bi12ihO0F7ajUjd5k+6e+Fl+WOybH/0BnrU/8zIszN9fzlG4qC0Fb0qaqO
 aEjX1qy+ccUC8i2yNsVH3aJzMcdFL00acYFOYcEhbvxpECzHuZSgpdmU+4SKv6mWqlezaWqardb
 8sxH1a2naBSFvYodB3umyZdl6li9gqCl/DC2Lc/+h0goRF45OlBo6aa3hzEaOVJb075076xOA+6
 +f5b+akVvWdBMsSSclfft3085YfC3Ugt4X9hv1cz0CPG/akWIdgkxHBcj7+xDEmgGsUuke8bDc5
 84=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a new static variable (loadpin_root_writable) to keep the
write-ability state of enforce. Remove set_sysctl and const qualify
loadpin_sysctl_table (moves into .rodata) as there is no longer need to
change the value of extra1. The new proc_handler_loadpin returns -EINVAL
when loadpin_root_writable is false and the kernel var (enforce) is
being written. The old way of modifying the write-ability of enforce
stays in loadpin_check and is still set by calling sb_is_writable.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Const qualifying ctl tables is part of the hardening effort in the linux
kernel.

Changes in v4:
- Ensure report_writable is called after the loadpin_root_writable is
  set. And leave the writable argument in report_writable to make this
  order more explicit.
- Link to v3: https://lore.kernel.org/r/20251222-jag-const_loadpin-v3-1-6463c440fb90@kernel.org

Changes in v3:
- Fix compilation for CONFIG_SYSCTL=n
- Link to v2: https://lore.kernel.org/r/20251219-jag-const_loadpin-v2-1-a1490ab35a1d@kernel.org

Changes in v2:
- Removed set_sysctl
- Added new static loadpin_root_writable var to hold the writable state
- Renamed the variable holding the writable state to loadpin_root_writable
- Link to v1: https://lore.kernel.org/r/20251215-jag-const_loadpin-v1-1-6842775f4e90@kernel.org
---

---
 security/loadpin/loadpin.c | 37 ++++++++++++++++---------------------
 1 file changed, 16 insertions(+), 21 deletions(-)

diff --git a/security/loadpin/loadpin.c b/security/loadpin/loadpin.c
index 273ffbd6defe1324d6688dec5f9fe6c9401283ed..8aeec0c4327e69c6c24ae28b791b6ead11c94f23 100644
--- a/security/loadpin/loadpin.c
+++ b/security/loadpin/loadpin.c
@@ -52,32 +52,29 @@ static DEFINE_SPINLOCK(pinned_root_spinlock);
 static bool deny_reading_verity_digests;
 #endif
 
+// initialized to false
+static bool loadpin_root_writable;
 #ifdef CONFIG_SYSCTL
-static struct ctl_table loadpin_sysctl_table[] = {
+
+static int proc_handler_loadpin(const struct ctl_table *table, int dir,
+				void *buffer, size_t *lenp, loff_t *ppos)
+{
+	if (!loadpin_root_writable && SYSCTL_USER_TO_KERN(dir))
+		return -EINVAL;
+	return proc_dointvec_minmax(table, dir, buffer, lenp, ppos);
+}
+
+static const struct ctl_table loadpin_sysctl_table[] = {
 	{
 		.procname       = "enforce",
 		.data           = &enforce,
 		.maxlen         = sizeof(int),
 		.mode           = 0644,
-		.proc_handler   = proc_dointvec_minmax,
-		.extra1         = SYSCTL_ONE,
+		.proc_handler   = proc_handler_loadpin,
+		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
 	},
 };
-
-static void set_sysctl(bool is_writable)
-{
-	/*
-	 * If load pinning is not enforced via a read-only block
-	 * device, allow sysctl to change modes for testing.
-	 */
-	if (is_writable)
-		loadpin_sysctl_table[0].extra1 = SYSCTL_ZERO;
-	else
-		loadpin_sysctl_table[0].extra1 = SYSCTL_ONE;
-}
-#else
-static inline void set_sysctl(bool is_writable) { }
 #endif
 
 static void report_writable(struct super_block *mnt_sb, bool writable)
@@ -131,7 +128,6 @@ static int loadpin_check(struct file *file, enum kernel_read_file_id id)
 	struct super_block *load_root;
 	const char *origin = kernel_read_file_id_str(id);
 	bool first_root_pin = false;
-	bool load_root_writable;
 
 	/* If the file id is excluded, ignore the pinning. */
 	if ((unsigned int)id < ARRAY_SIZE(ignore_read_file_id) &&
@@ -152,7 +148,6 @@ static int loadpin_check(struct file *file, enum kernel_read_file_id id)
 	}
 
 	load_root = file->f_path.mnt->mnt_sb;
-	load_root_writable = sb_is_writable(load_root);
 
 	/* First loaded module/firmware defines the root for all others. */
 	spin_lock(&pinned_root_spinlock);
@@ -168,8 +163,8 @@ static int loadpin_check(struct file *file, enum kernel_read_file_id id)
 	spin_unlock(&pinned_root_spinlock);
 
 	if (first_root_pin) {
-		report_writable(pinned_root, load_root_writable);
-		set_sysctl(load_root_writable);
+		loadpin_root_writable = sb_is_writable(pinned_root);
+		report_writable(pinned_root, loadpin_root_writable);
 		report_load(origin, file, "pinned");
 	}
 

---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251215-jag-const_loadpin-761f052f76c4

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

