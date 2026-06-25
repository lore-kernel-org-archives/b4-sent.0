From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 25 Jun 2026 22:38:13 +0200
Subject: [PATCH v3 01/10] sysctl: Move default converter assignment out of
 do_proc_dointvec
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260625-jag-dovec_consolidate-v3-1-176ee192bcaf@kernel.org>
References: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
In-Reply-To: <20260625-jag-dovec_consolidate-v3-0-176ee192bcaf@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1599;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=Po1w8AN+mSOWB/x8v0wNXpBi3Lxda37rouqhi5RaKeo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGo9kd6fNTG/zt3OrVoJy6PICMCoQUu+vVWbe
 Obma2YDiM6J14kBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJqPZHeAAoJELqXzVK3
 lkFPs9kMAIDKnhk1Jr3YqVYkbQrAmKLVHHtW730EHiQwQ8+ZQbHoWhbBIeIAWFFYGtt/ngSvbgC
 d9XXULwgZOC2gccqMW7ueBgInXsmb+nDDSMxDnMnXqWMoN/N0iHooy5BSc8lzK0Xb7nyXjohEgy
 w/jiYEn0axI6OsP98h7SR2Db9O1bqLzW+hTbxUbVXMRu04+Wp9aNOO11UonmovT7ZNToza1pBQV
 zTkoJLYSjCsFat8kTGSK86P47FOv3RaPnj/mGmjRIleFcYeSZVsYErv2ihomFtw7hMYTeT+/0a2
 TW5eHBTKi7PCfx+GOiM7hhcvUbDo2xEbjkRT5iT25GKqdHD1QmKV3iCxs+s5ZiLVx1O8S8F7tAK
 vd60idscz/FJltF7IdDKB05FP/679JrWehBCcS2b30Q7RQsgG60qhxLN9ejwtY47jlAit3BY2aj
 G/vfRFBvVPsOaOSlTeS/a1rbxXn/XxrqlXFqH7G2PNhoTak5QjYZ1MTFS8Xl8zjB/GEG6IPSIO6
 cE=
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
index c9efb17cc255cffee08b5299c3e7bb947adf3f2b..e53e60213462fd1b99b8c36e19e1e5c47d20e6c5 100644
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
@@ -1090,6 +1087,8 @@ int proc_dointvec_conv(const struct ctl_table *table, int dir, void *buffer,
 		       int (*conv)(bool *negp, unsigned long *u_ptr, int *k_ptr,
 				   int dir, const struct ctl_table *table))
 {
+	if (!conv)
+		conv = do_proc_int_conv;
 	return do_proc_dointvec(table, dir, buffer, lenp, ppos, conv);
 }
 

-- 
2.50.1

