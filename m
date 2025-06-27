From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 27 Jun 2025 11:27:29 +0200
Subject: [PATCH 5/5] sysctl: rename kern_table -> sysctl_subsys_table
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250627-jag-sysctl-v1-5-20dd9801420b@kernel.org>
References: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
In-Reply-To: <20250627-jag-sysctl-v1-0-20dd9801420b@kernel.org>
To: Kees Cook <kees@kernel.org>, Shuah Khan <shuah@kernel.org>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Danilo Krummrich <dakr@kernel.org>, 
 Andrew Morton <akpm@linux-foundation.org>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-kselftest@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2432;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=hgTq3HJakHDLAQL9R275nXbuleoJE/PtptKFtlOZlIs=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGheZItRvg7iUt/llY0jbi3S8p4tXdqPpP3ES
 PH4SAld/qySPIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoXmSLAAoJELqXzVK3
 lkFPkkcL/0kQbR1sj7lbluFeCpSjtNkpKm+jLiXZcrRmAe9K4iSgODeEZRXR7j+6fu9IqphE3Gm
 Z5lm4OhRmxF/P21L5oBXMHdsBsmEyFU5qQVQTGTCq+qZIHJSm7p+XsvQ04r/vBDcVjWHiSVDnOH
 4fF+pPRuoPm2EQP/q2zT4tYvaajLN/8mBOVDxiokci+6K8PDk/O6dn97UYlQIS4gX8qj6CFHE1H
 N5dz1iSBTb5coUDKVmuBbaqEL8r1MXo4fiVeVtX3qvha4mEB4QdwZhL0U/DtNXzu0KGhEhtu0vB
 ZdautBKdIG/ui5nC7p5HUam91iIVu0bnfrHmZ1VNuFkk5nSSGEV/APDcz5AbIpzAWhzYTfore0h
 6erbmuF00MVdrGY9W/T+rFU6pYYy6q/ftmH8yZzRds0H30FAjmj/CEIxlxv74C53FXR+TQvcwEK
 OrCAqwpvdhNlacaC3dvBEwF8mPBZ7cR+czVEYERECXdd+RYsqgyPDgsjPCc3Cq+9eZFI4Ujo3f6
 fE=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Renamed sysctl table from kern_table to sysctl_subsys_table and grouped
the two arch specific ctls to the end of the array.

This is part of a greater effort to move ctl tables into their
respective subsystems which will reduce the merge conflicts in
kernel/sysctl.c.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sys.c    |  1 -
 kernel/sysctl.c | 22 +++++++++++-----------
 2 files changed, 11 insertions(+), 12 deletions(-)

diff --git a/kernel/sys.c b/kernel/sys.c
index bbeee62f9abcdf18cdf5cdb06271476b048357ae..18a037cc6f61a339f1f21af9c26b25ecca1ae43c 100644
--- a/kernel/sys.c
+++ b/kernel/sys.c
@@ -210,7 +210,6 @@ static int __init init_overflow_sysctl(void)
 
 postcore_initcall(init_overflow_sysctl);
 
-
 /*
  * Returns true if current's euid is same as p's uid or euid,
  * or has CAP_SYS_NICE to p's user_ns.
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 21b70443aea75ae3212f70e5ce7efbfdf8a4f75b..cb6196e3fa993daa21704d190baf366084e014f7 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -1454,7 +1454,7 @@ int proc_do_static_key(const struct ctl_table *table, int write,
 	return ret;
 }
 
-static const struct ctl_table kern_table[] = {
+static const struct ctl_table sysctl_subsys_table[] = {
 #ifdef CONFIG_PROC_SYSCTL
 	{
 		.procname	= "sysctl_writes_strict",
@@ -1465,15 +1465,6 @@ static const struct ctl_table kern_table[] = {
 		.extra1		= SYSCTL_NEG_ONE,
 		.extra2		= SYSCTL_ONE,
 	},
-#endif
-#ifdef CONFIG_SYSCTL_ARCH_UNALIGN_ALLOW
-	{
-		.procname	= "unaligned-trap",
-		.data		= &unaligned_enabled,
-		.maxlen		= sizeof (int),
-		.mode		= 0644,
-		.proc_handler	= proc_dointvec,
-	},
 #endif
 	{
 		.procname	= "ngroups_max",
@@ -1489,6 +1480,15 @@ static const struct ctl_table kern_table[] = {
 		.mode		= 0444,
 		.proc_handler	= proc_dointvec,
 	},
+#ifdef CONFIG_SYSCTL_ARCH_UNALIGN_ALLOW
+	{
+		.procname	= "unaligned-trap",
+		.data		= &unaligned_enabled,
+		.maxlen		= sizeof(int),
+		.mode		= 0644,
+		.proc_handler	= proc_dointvec,
+	},
+#endif
 #ifdef CONFIG_SYSCTL_ARCH_UNALIGN_NO_WARN
 	{
 		.procname	= "ignore-unaligned-usertrap",
@@ -1502,7 +1502,7 @@ static const struct ctl_table kern_table[] = {
 
 int __init sysctl_init_bases(void)
 {
-	register_sysctl_init("kernel", kern_table);
+	register_sysctl_init("kernel", sysctl_subsys_table);
 
 	return 0;
 }

-- 
2.47.2

