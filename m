From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 17 Oct 2025 10:32:16 +0200
Subject: [PATCH 6/7] sysctl: Create pipe-max-size converter using sysctl
 UINT macros
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251017-jag-sysctl_jiffies-v1-6-175d81dfdf82@kernel.org>
References: <20251017-jag-sysctl_jiffies-v1-0-175d81dfdf82@kernel.org>
In-Reply-To: <20251017-jag-sysctl_jiffies-v1-0-175d81dfdf82@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=3090;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=iaAU8r3Z3qFlnpkaBE2GnAyYsz/OD81BAxEiYGaHlFY=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjx/0JMXzw+IGByIDEf2hnHT2lY4g4dLxh9u
 m7nEtU+LVnW0YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8f9CAAoJELqXzVK3
 lkFPV+wMAJd5VdIzIhNGt1xU7YgreVISGoU+98Uv0nB8pWNGvR4hMmxuAhd5fyee4PZ5zIoz+Y5
 1zg9FEtrkqI+2NUQF2He/sZNz7ch3e8ppmFbh7PcnqiokoVlia0kn4OHXVCI+Mfur0xX3TJAkst
 9NRbmVd3JL0QzuzV79KReAHc8pHWSB16l+po3l8TKwblZ+3Rvi8S/EPWqE75xykrPB+GVvcg7hD
 CMdOq7HWUgaB2tZI+j773cyHkI3RYfgAh+RElRR1Z3UOCvmMK/z95QpFsc3CJp5JdOgrQnZ5awo
 QNapCYBXTDq/XYK4eCjBvs4fP/zAt0xXzIATGtLpoP5CCp7rBGymdvzXgufzQh8kuZLTJ10w/cW
 WF/gDQEUBnqd3nqYxPxRupzJ4pLMecRzmPNwS34hugvJ+FjOwzV6j7rp4ys9FWaEagPbwJ5R3bR
 x14oD5NLKLEoSZqihVgyvGB6SXaVKH31FQjtB2/QMzTpzfR0Yc5fIQlK3EmVxNSuraHzUwA6AG5
 J4=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Create a converter for the pipe-max-size proc_handler using the
SYSCTL_UINT_CONV_CUSTOM. Move SYSCTL_CONV_IDENTITY macro to the sysctl
header to make it available for pipe size validation. Keep returning
-EINVAL when (val == 0) by using a range checking converter and setting
the minimal valid value (extern1) to SYSCTL_ONE. Keep round_pipe_size by
passing it as the operation for SYSCTL_USER_TO_KERN_INT_CONV.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 fs/pipe.c              | 26 ++++++--------------------
 include/linux/sysctl.h |  1 +
 kernel/sysctl.c        |  2 --
 3 files changed, 7 insertions(+), 22 deletions(-)

diff --git a/fs/pipe.c b/fs/pipe.c
index 2431f05cb788f5bd89660f0fc6f4c4696e17d5dd..974faf06a3136fff7a382e575514d84fcf86183c 100644
--- a/fs/pipe.c
+++ b/fs/pipe.c
@@ -1479,31 +1479,16 @@ static struct file_system_type pipe_fs_type = {
 };
 
 #ifdef CONFIG_SYSCTL
-static int do_proc_dopipe_max_size_conv(unsigned long *lvalp,
-					unsigned int *valp, int write,
-					const struct ctl_table *table)
-{
-	if (write) {
-		unsigned int val;
-
-		val = round_pipe_size(*lvalp);
-		if (val == 0)
-			return -EINVAL;
-
-		*valp = val;
-	} else {
-		unsigned int val = *valp;
-		*lvalp = (unsigned long) val;
-	}
-
-	return 0;
-}
+static SYSCTL_USER_TO_KERN_UINT_CONV(_pipe_maxsz, round_pipe_size)
+static SYSCTL_UINT_CONV_CUSTOM(_pipe_maxsz,
+			       sysctl_user_to_kern_uint_conv_pipe_maxsz,
+			       sysctl_kern_to_user_uint_conv, true)
 
 static int proc_dopipe_max_size(const struct ctl_table *table, int write,
 				void *buffer, size_t *lenp, loff_t *ppos)
 {
 	return do_proc_douintvec(table, write, buffer, lenp, ppos,
-				 do_proc_dopipe_max_size_conv);
+				 do_proc_uint_conv_pipe_maxsz);
 }
 
 static const struct ctl_table fs_pipe_sysctls[] = {
@@ -1513,6 +1498,7 @@ static const struct ctl_table fs_pipe_sysctls[] = {
 		.maxlen		= sizeof(pipe_max_size),
 		.mode		= 0644,
 		.proc_handler	= proc_dopipe_max_size,
+		.extra1		= SYSCTL_ONE,
 	},
 	{
 		.procname	= "pipe-user-pages-hard",
diff --git a/include/linux/sysctl.h b/include/linux/sysctl.h
index 9396bb421cd5e1e9076de0c77c45a870c453aee1..ee5e2b3f47db834b084ac0fc4108bf28177b6949 100644
--- a/include/linux/sysctl.h
+++ b/include/linux/sysctl.h
@@ -59,6 +59,7 @@ extern const int sysctl_vals[];
 #define SYSCTL_LONG_ONE		((void *)&sysctl_long_vals[1])
 #define SYSCTL_LONG_MAX		((void *)&sysctl_long_vals[2])
 
+#define SYSCTL_CONV_IDENTITY(val) (val)
 /**
  *
  * "dir" originates from read_iter (dir = 0) or write_iter (dir = 1)
diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 6750ddbc15b2bb9ee9de0d48ac999a4c3a2ec5d6..d2e756ee3717b07fd848871267656ee0ed7d9268 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -354,8 +354,6 @@ static void proc_put_char(void **buf, size_t *size, char c)
 	}
 }
 
-#define SYSCTL_CONV_IDENTITY(val) val
-
 static SYSCTL_USER_TO_KERN_INT_CONV(, SYSCTL_CONV_IDENTITY)
 static SYSCTL_KERN_TO_USER_INT_CONV(, SYSCTL_CONV_IDENTITY)
 

-- 
2.50.1

