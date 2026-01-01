From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 01 Jan 2026 13:57:05 +0100
Subject: [PATCH v2 1/9] sysctl: Move default converter assignment out of
 do_proc_dointvec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260101-jag-dovec_consolidate-v2-1-ff918f753ba9@kernel.org>
References: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
In-Reply-To: <20260101-jag-dovec_consolidate-v2-0-ff918f753ba9@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1599;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=BttYzFF+xjDCiXPSwOn5xmsY105yRYbvY3nWA/ZGsJo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGlWbyopSbpjacVeuho9vpVpKianahjMT25EN
 y0uNhNJdmNEj4kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJpVm8qAAoJELqXzVK3
 lkFPBUML/0D4SkMtKjl6Dt82vq7nvCRL7oKLZjkRsAuqCeOgUNgWjCV2IdQsp/4Lwa1Mw8LZSfq
 9lO/4624pX9vJeQ9xDtxl3ZmYFLP8wQU+BtyV6+mM+647Exdvaoof2qt7bg5vtF5YmQ7bStBMPu
 udREwH3xwKWttbRbHDuNlsQb4OX+ILbRKn3gXgROmpqOErid/8cmYsZwZAXR9ioJbgXevY79MSW
 7S6xc72zaHU5k2vaSUFvXuTPByEpfYbTsCVRAbfmcAIwqDMqNc7JtP+xUWrLsu8B4P+NXOxqTKm
 sMME7pe1zCM5X0Lub2wtqf55OqFlan1tEMKvQM8rqq3usIV18zQxLIk3v98gaIjvtZhZPnF/BLC
 hSV1/pbu151ObTOFCaLLjjHtL7G1XcrcCoi7LE77LSs570Vh6ZFYVsAsSOGzJkn2VFWTtCy7cM1
 n1tb7Z6f/gSMLH+xiKgG3j4FxzQIjukVYQe5I8Z1+ELsRwt1u/qSPS7oZ/WRYb2LFDRlMiKaDS6
 Vo=
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

