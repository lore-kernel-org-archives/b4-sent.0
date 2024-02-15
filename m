From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 15 Feb 2024 10:02:41 +0100
Subject: [PATCH 1/3] utest/tracefs-utest: add missing include
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240215-utest-fixes-v1-1-24678d859de2@gmail.com>
References: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
In-Reply-To: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707987764; l=532;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=RzwubJwK0n2/ywZtJ5O3qrBEJeAAen2BvWlXzylk00w=;
 b=/aZm0dyIJkZyKx+5XKtxGdfUWZxc3VST5x4tvllBN67s1geqBaMRCQ+l74PD6cTkJ9y/Nhtaw
 4EDmkPH49sJAu1wNcK4pR8aM6/X9t+Qvd/guWd8lO6hm3Bs9AnMie7Y
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes FTBFS with clang >=15

Fixes: 845f16976929 ("libtracefs: Add unit tests")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
 utest/tracefs-utest.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/utest/tracefs-utest.c b/utest/tracefs-utest.c
index 963fac7..a798ace 100644
--- a/utest/tracefs-utest.c
+++ b/utest/tracefs-utest.c
@@ -19,6 +19,8 @@
 #include <sys/mount.h>
 #include <sys/syscall.h>
 
+#include <linux/limits.h>
+
 #include <CUnit/CUnit.h>
 #include <CUnit/Basic.h>
 

-- 
2.43.0

