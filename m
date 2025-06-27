From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 27 Jun 2025 11:27:27 +0200
Subject: [PATCH 3/5] uevent: mv uevent_helper into kobject_uevent.c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250627-jag-sysctl-v1-3-20dd9801420b@kernel.org>
References: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
In-Reply-To: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1861;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=BfB8j0Uenzx8HLuqS3XAnJOtPTaoOBqEdT3unxo3Qp4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGheZIpR9w3Poudl1+IA2Xz/6g+srEOImFNlL
 M7P49LWN92qoIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoXmSKAAoJELqXzVK3
 lkFPHIkL/2fGery5RFEqRkjNFgNIwk4Gy8ErpUzkJp0XG+vzv2iuUaVCeRG55yL7MR6yG/4IF8/
 oAnZucFlsU4dgjAc5cAPVkMu2BYe1ngpdOogZgzQcG4d+oU0aq6j82JfgO+yA1fGqVaGkAb7+ei
 Vuqu7vJ11zrg98sglHgOegaGThXIkBerBWaF4IszVLQ8hMPRvoDFeu580G1Tl2DZ1pSOPG7Hkgx
 od35wzUsD37DTUjm28zuOS0wHcz5fAJ+hpu34mNfWyoIRXD6ZCv5h1iT73AnIHpyKkwGBAmQkDV
 kMmI5pp/sZo1xs29per70D7eBEY+R9h+zf4hP266asUipFzYhiwpJDtqVxRqMx9B9ex4mvH7hRE
 7ghc432YBaqDYpX7mpSoCjDjCwwxYkmPH6NoBIkidxsPc+vfpBEd/+nChBiNqo1GDgxN80AhNRk
 7XQWwqsLZJAhd5BHBZNEKrzb1Bmyu0k2byi6ehR5fPyfOLKnNfQ2WE2peaZao+wGb9AxClCBsR6
 E0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move both uevent_helper table into lib/kobject_uevent.c. Place the
registration early in the initcall order with postcore_initcall.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c      |  9 ---------
 lib/kobject_uevent.c | 20 ++++++++++++++++++++
 2 files changed, 20 insertions(+), 9 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 0716c7df7243dc38f0a49c7cae78651c3f75f5a3..2df63b69edf6fd21a58584d670e75e6f26a6e5cc 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1474,15 +1474,6 @@ static const struct ctl_table kern_table[] = {
 		.mode		= 0644,
 		.proc_handler	= proc_dointvec,
 	},
-#endif
-#ifdef CONFIG_UEVENT_HELPER
-	{
-		.procname	= "hotplug",
-		.data		= &uevent_helper,
-		.maxlen		= UEVENT_HELPER_PATH_LEN,
-		.mode		= 0644,
-		.proc_handler	= proc_dostring,
-	},
 #endif
 	{
 		.procname	= "overflowuid",
diff --git a/lib/kobject_uevent.c b/lib/kobject_uevent.c
index b7f2fa08d9c82c2838b703f3fd25f6e43b88b68a..78e16b95d2101a01c442f62ad9b9133f3f8533c2 100644
--- a/lib/kobject_uevent.c
+++ b/lib/kobject_uevent.c
@@ -826,3 +826,23 @@ static int __init kobject_uevent_init(void)
 
 postcore_initcall(kobject_uevent_init);
 #endif
+
+#ifdef CONFIG_UEVENT_HELPER
+static const struct ctl_table uevent_helper_sysctl_table[] = {
+	{
+		.procname	= "hotplug",
+		.data		= &uevent_helper,
+		.maxlen		= UEVENT_HELPER_PATH_LEN,
+		.mode		= 0644,
+		.proc_handler	= proc_dostring,
+	},
+};
+
+static int __init init_uevent_helper_sysctl(void)
+{
+	register_sysctl_init("kernel", uevent_helper_sysctl_table);
+	return 0;
+}
+
+postcore_initcall(init_uevent_helper_sysctl);
+#endif

-- 
2.47.2

