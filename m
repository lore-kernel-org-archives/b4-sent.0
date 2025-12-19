From: Joel Granados <joel.granados@kernel.org>
Date: Fri, 19 Dec 2025 13:15:52 +0100
Subject: [PATCH 1/9] sysctl: Move default converter assignment out of
 do_proc_dointvec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251219-jag-dovec_consolidate-v1-1-1413b92c6040@kernel.org>
References: <20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org>
In-Reply-To: <20251219-jag-dovec_consolidate-v1-0-1413b92c6040@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1599;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=BttYzFF+xjDCiXPSwOn5xmsY105yRYbvY3nWA/ZGsJo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlFQgRMtizYR9OYfeMjw7pycCr20q/WRljNv
 Gv7AtsSvdGWWIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpRUIEAAoJELqXzVK3
 lkFPwrIL/0iqyDLEk1RhmqSMkosxAUAybbbCK4smGes4JaXl8BHioW4tZycsI6h2HCNiTXaXOru
 IvIXurtl6sXky1KuZ+xH50ynenFebFbsbCjPSbGrF0dU5QiKc8iPkritOe8xPeU3GqwNLMpb72k
 tm330e3TYbYuJWCJj64ruZbsYZID4sBhRD1FW835FOT8XzeUCkYAML7YqpKVBTVVN6k5F7l+ZlW
 Lkaq6r25AmPFhkq9F+CZQJirk0Wip5O53b4hnlpKR3QMkVAoKOuno+PaN7s4oxJ2Vo8teWNh3jX
 KO8f+TBapGhhY70TJye2Y8ff4eacLQuP36M/LH3zzzZJZF2H28B8hgT7Z319yME/VkzDfI/CJd1
 qMrpTI5rj5JNfbTUU8EnjdLdxoCZZp+BB9W+WQtrYjQjB+pkSX214bWeETdooaGVC67fkZnvejR
 9FCJaz71ZYpPPNp61hy4mdH305OI7B3vfaohWSfkzi5bLjqmqaikxTbfou9Fbq7ZgBr1u9L/Q17
 dY=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Move the converter assignment out of do_proc_dointvec into the caller.
Both the test for NULL and the assignment are meant to stay within the
sysctl.c context. This is in preparation of using a typed macro to for
the integer proc vector function.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 7 +++----
 1 file changed, 3 insertions(+), 4 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index caee1bd8b2afc0927e0dcdd33c0db41c87518bfb..284ad6c277e8b52177cca3153acf02ff39de17f0 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -591,9 +591,6 @@ static int do_proc_dointvec(const struct ctl_table *table, int dir,
 	vleft = table->maxlen / sizeof(*i);
 	left = *lenp;
 
-	if (!conv)
-		conv = do_proc_int_conv;
-
 	if (SYSCTL_USER_TO_KERN(dir)) {
 		if (proc_first_pos_non_zero_ignore(ppos, table))
 			goto out;
@@ -840,7 +837,7 @@ int proc_dobool(const struct ctl_table *table, int dir, void *buffer,
 int proc_dointvec(const struct ctl_table *table, int dir, void *buffer,
 		  size_t *lenp, loff_t *ppos)
 {
-	return do_proc_dointvec(table, dir, buffer, lenp, ppos, NULL);
+	return do_proc_dointvec(table, dir, buffer, lenp, ppos, do_proc_int_conv);
 }
 
 /**
@@ -1074,6 +1071,8 @@ int proc_dointvec_conv(const struct ctl_table *table, int dir, void *buffer,
 		       int (*conv)(bool *negp, unsigned long *u_ptr, int *k_ptr,
 				   int dir, const struct ctl_table *table))
 {
+	if (!conv)
+		conv = do_proc_int_conv;
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos, conv);
 }
 

-- 
2.50.1

