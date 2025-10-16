From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 16 Oct 2025 14:57:57 +0200
Subject: [PATCH v2 11/11] sysctl: Create macro for user-to-kernel uint
 converter
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251016-jag-sysctl_conv-v2-11-a2f16529acc4@kernel.org>
References: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
In-Reply-To: <20251016-jag-sysctl_conv-v2-0-a2f16529acc4@kernel.org>
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Kees Cook <kees@kernel.org>, Joel Granados <joel.granados@kernel.org>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1590;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=xP7pIUDrYB9KQ96n73WKDlnF/Xja1RjBW7d+EpQMu6M=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGjw6+har3JgRhpb7X+yT2YZZPpLBCCBReffZ
 4u3JcnC1qd+QYkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJo8OvoAAoJELqXzVK3
 lkFPC0wL/2nGgxIGHWL6XlsbrXL1jKFc+w1KHAEWTglDc1POPTTpP0zMycx8vI8WergoKcGZm0a
 8aT2lbab9gWuYsWRK4OQKgIZtfFNKmVNza80mg6bwPVMvOe8UFUWasZDXxWkhUqND35JfHebMET
 HxjVwILebsi/RFWCkyjpqRdcWUESrGwWQ7jxUj4087BkUmtZ2LXt8FUGTyIUxVktZltIUtHwtm0
 cXQIrDUtT7Dt646yB/2LioExvw64/q68vWZGXmCMoz6r1lHFBRLwaL2DrrezclwqRPjNcAYZVeA
 HjiI9bG5e2y7mOOYP0ZLpbvkobJzMVBDVjNJuPXv6rLy8wTBjXE52k7Uj/uXf/j+IuLB57uANrG
 Wxk66e3TUicvF0V3XVEwHeGrY4oTDt4TQeP6jhhwvfBQ5Uh2cjq+EhxJeVvlgrwmTNLejWIc5Ac
 c3oyCTpJpMF2SGQW3W+ClMH2oAwoKENliAh1ow2rgFEGsdBDPUKSuepPQ6ShlEGg0UnHEDjBiw5
 qI=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace sysctl_user_to_kern_uint_conv function with
SYSCTL_USER_TO_KERN_UINT_CONV macro that accepts u_ptr_op parameter for
value transformation. Replacing sysctl_kern_to_user_uint_conv is not
needed as it will only be used from within sysctl.c. This is a
preparation commit for creating a custom converter in fs/pipe.c. No
Functional changes are intended.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 kernel/sysctl.c | 18 +++++++++++-------
 1 file changed, 11 insertions(+), 7 deletions(-)

diff --git a/kernel/sysctl.c b/kernel/sysctl.c
index 750c94313c1fd23551e03f455585d2dd94f3c758..9b08573bbacdfa0ec036a8043561253c21300c9a 100644
--- a/kernel/sysctl.c
+++ b/kernel/sysctl.c
@@ -462,15 +462,19 @@ static SYSCTL_INT_CONV_CUSTOM(_ms_jiffies_minmax,
 			      sysctl_user_to_kern_int_conv_ms,
 			      sysctl_kern_to_user_int_conv_ms, true)
 
-static int sysctl_user_to_kern_uint_conv(const unsigned long *u_ptr,
-					 unsigned int *k_ptr)
-{
-	if (*u_ptr > UINT_MAX)
-		return -EINVAL;
-	WRITE_ONCE(*k_ptr, *u_ptr);
-	return 0;
+#define SYSCTL_USER_TO_KERN_UINT_CONV(name, u_ptr_op)		\
+int sysctl_user_to_kern_uint_conv##name(const unsigned long *u_ptr,\
+					unsigned int *k_ptr)	\
+{								\
+	unsigned long u = u_ptr_op(*u_ptr);			\
+	if (u > UINT_MAX)					\
+		return -EINVAL;					\
+	WRITE_ONCE(*k_ptr, u);					\
+	return 0;						\
 }
 
+static SYSCTL_USER_TO_KERN_UINT_CONV(, SYSCTL_CONV_IDENTITY)
+
 static int sysctl_kern_to_user_uint_conv(unsigned long *u_ptr,
 					 const unsigned int *k_ptr)
 {

-- 
2.50.1

