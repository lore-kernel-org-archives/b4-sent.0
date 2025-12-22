From: Joel Granados <joel.granados@kernel.org>
Date: Mon, 22 Dec 2025 23:36:35 +0100
Subject: [PATCH v3] loadpin: Implement custom proc_handler for enforce
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251222-jag-const_loadpin-v3-1-6463c440fb90@kernel.org>
X-B4-Tracking: v=1; b=H4sIAPLHSWkC/33N0QrCIBTG8VcZXmd4nM7WVe8REbYdN2vo0CHF2
 LvndlUQXf4/OL8zk4jBYiTHYiYBk43WuxzlriBNr12H1La5CWdcAgdJ77qjjXdxug5et6N1VFV
 gmORGVY0g+W4MaOxzM8+X3L2Nkw+v7UWCdf2nJaBAq4PgSkkjsGanBwaHw96Hjqxc4p9E/Yvgm
 dAgaqZvpdTQfhHLsrwBCoDkwvYAAAA=
X-Change-ID: 20251215-jag-const_loadpin-761f052f76c4
To: Kees Cook <kees@kernel.org>, Paul Moore <paul@paul-moore.com>, 
 James Morris <jmorris@namei.org>, "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-security-module@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4618;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=3+poNGbHruGysw5DnYkIGnmPBMbtUe+edN4yORNzzag=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlJx/+5+gALaHGodIxIKHjfC9MqMqCbbKqBS
 Wp8oWRQzcmG44kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpScf/AAoJELqXzVK3
 lkFPhmwL/jVtVOv54Ct/CNhYmB5ElWHmoxLLdRGoH8eO93MawlgPg9hQRzHeCgBw2jnDqn0UBwk
 N0f+epO1fySTHowyhUjyzIwIOkLBmI9Z2FSQ9epA9oLObcpfA3hOd4LXbKgmuqr0nsBkjGP9biY
 kHna2M1atJf+7Xebd2sjGtXIEPFubyzQNL/vvA0bfibOZBRyYxRd/mOC16Y53aLwWSDiQmsTJwx
 w9rIwRJ6aBHZSSolGjL5hvhgRXTk8S+4LiHj8Upb3tfMlVMbAA0iSCS/0I95AI4id0+DwPyG8c4
 LRzSDJ7ZrWmvexEquDfndB7qmO9ETK43K+fCcWY8kBVddcy8LEYNbVghkAKyU0Y6EQGqu6hFVC1
 LVvkQxlGopWdCBoWeoqplYsnY9uz1nmckSc1CzfAsnYvITReIz5K6ASJ83IMd4n8m/vgE4+SBfO
 raDZalyojIAsv50TVNCtyOxesY5lVPcgUxpfBuURPUc4GdFH06sNftQd1KYODMWIim1X2IX0Od5
 Y0=
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
stayes in loadpin_check and is still set by calling sb_is_writable.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Const qualifying ctl tables is part of the hardening effort in the linux
kernel.

Changes in v3:
- Fix compilation for CONFIG_SYSCTL=n
- Link to v2: https://lore.kernel.org/r/20251219-jag-const_loadpin-v2-1-a1490ab35a1d@kernel.org

Changes in v2:
- Removed set_sysctl
- Added new static loadpin_root_writable var to hold the writable state
- Renamed the variable holding the writable state to loadpin_root_writable
- Link to v1: https://lore.kernel.org/r/20251215-jag-const_loadpin-v1-1-6842775f4e90@kernel.org
---
Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 security/loadpin/loadpin.c | 43 +++++++++++++++++++------------------------
 1 file changed, 19 insertions(+), 24 deletions(-)

diff --git a/security/loadpin/loadpin.c b/security/loadpin/loadpin.c
index 273ffbd6defe1324d6688dec5f9fe6c9401283ed..a6c7e4bfa45d3568e8c36e184388ee7858ba022e 100644
--- a/security/loadpin/loadpin.c
+++ b/security/loadpin/loadpin.c
@@ -52,45 +52,42 @@ static DEFINE_SPINLOCK(pinned_root_spinlock);
 static bool deny_reading_verity_digests;
 #endif
 
+static bool loadpin_root_writable;
 #ifdef CONFIG_SYSCTL
-static struct ctl_table loadpin_sysctl_table[] = {
+// initialized to false
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
 
-static void report_writable(struct super_block *mnt_sb, bool writable)
+static void report_writable(struct super_block *mnt_sb)
 {
 	if (mnt_sb->s_bdev) {
 		pr_info("%pg (%u:%u): %s\n", mnt_sb->s_bdev,
 			MAJOR(mnt_sb->s_bdev->bd_dev),
 			MINOR(mnt_sb->s_bdev->bd_dev),
-			writable ? "writable" : "read-only");
+			loadpin_root_writable ? "writable" : "read-only");
 	} else
 		pr_info("mnt_sb lacks block device, treating as: writable\n");
 
-	if (!writable)
+	if (!loadpin_root_writable)
 		pr_info("load pinning engaged.\n");
 }
 
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
+		report_writable(pinned_root);
+		loadpin_root_writable = sb_is_writable(pinned_root);
 		report_load(origin, file, "pinned");
 	}
 

---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251215-jag-const_loadpin-761f052f76c4

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

