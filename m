From: Joel Granados <j.granados@samsung.com>
Date: Fri, 26 Jan 2024 12:53:10 +0100
Subject: [PATCH] MAINTAINERS: Update sysctl tree location
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240126-for-6-8-v1-1-9695cdd9f8ef@samsung.com>
X-B4-Tracking: v=1; b=H4sIACWds2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDQyMz3bT8Il0zXQtdC9PkVMPkZDMzA7MkJaDqgqLUtMwKsEnRsbW1ALV
 8bghZAAAA
To: Luis Chamberlain <mcgrof@kernel.org>
Cc: Kees Cook <keescook@chromium.org>, linux-kernel@vger.kernel.org, 
 linux-fsdevel@vger.kernel.org, Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=1368;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=HPzyLD05I4KtL5puu5ieEBvpSzlKvZSf692MeTRD/W8=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBls50uspKcXsj8qrMDVqGyepCioSHe3rOrcOGfm
 54ZYMwuEqyJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZbOdLgAKCRC6l81St5ZB
 TwJaC/9FXc3g2NJntHWyQL3KlEAlSfdCC/EaHcjQAlqDr8E64qo5+KKNTkfTvqA8hhv6bcZxYbd
 ddwPPgQ9TMcbAF3QNFabMUOPO9jeFTHUCCBtYLLl8DPlddE8zG8rwi/mPRvZDYPSeDHSApz7c6u
 HapJQ7bvtI5u0r/3GbGERUx7v75w9BYuqmrybG/4PLjuq3HS/zHQpCq3FZiBLVWtDZHayPz2iyA
 N8n6QgtoomxtmXEaP9MnmzTVZxtqrSCu+18cNnCyxtjRRJewnEqYyZ+yDWBTcpoCd419g6atKAO
 kuk6b7vSuAHqakJYUYH7phreGRzQ7zxqVrC5b3vLAoAbrWkmeLV3hwOK4sK4NCyRKoGjezsNeU/
 zeUraXW23MJKbFxqqz1/E5cMQHgg4fEdSBfYfugMP/3u97vGitt0jLAgwW1a8HRH5mgsyjBl97R
 V7V6z0mA6qn4t/7k4RvH2NVm5I5n56sNFaOlYNzL0TFgA4ac4BQnrQsUZJjR1E9t6uMAw=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

To more efficiently co-maintain the sysctl subsystem a shared repository
has been created at https://git.kernel.org/pub/scm/linux/kernel/git/sysctl/sysctl.git
and the sysctl-next branch that Luis Chamberlain (mcgrof@kernel.org) maintained at
https://git.kernel.org/pub/scm/linux/kernel/git/mcgrof/linux.git/log/?h=sysctl-next
has moved to the shared sysctl-next branch located at
https://git.kernel.org/pub/scm/linux/kernel/git/sysctl/sysctl.git/log/?h=sysctl-next.
This commit changes the sysctl tree in MAINTAINERS to reflect this change.

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 MAINTAINERS | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 8d1052fa6a69..adf69ab891e0 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -17616,7 +17616,7 @@ M:	Joel Granados <j.granados@samsung.com>
 L:	linux-kernel@vger.kernel.org
 L:	linux-fsdevel@vger.kernel.org
 S:	Maintained
-T:	git git://git.kernel.org/pub/scm/linux/kernel/git/mcgrof/linux.git sysctl-next
+T:	git git://git.kernel.org/pub/scm/linux/kernel/git/sysctl/sysctl.git sysctl-next
 F:	fs/proc/proc_sysctl.c
 F:	include/linux/sysctl.h
 F:	kernel/sysctl-test.c

---
base-commit: 6613476e225e090cc9aad49be7fa504e290dd33d
change-id: 20240126-for-6-8-85ce1cc6606b

Best regards,
-- 
Joel Granados <j.granados@samsung.com>

