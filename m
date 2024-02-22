From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 22 Feb 2024 11:12:44 +0100
Subject: [PATCH v2 1/3] utest/tracefs-utest: include linux/limits.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-utest-fixes-v2-1-ba9cd06b41d3@gmail.com>
References: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
In-Reply-To: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708596765; l=871;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=fJxacPVoyFtCYtoqXqDtpb725G8Jw3FCfY22Xy5jABM=;
 b=Idf+mPBK8Jeu1EXfl3woR8JPDGgjJ/7P643F1zkJzj9BaGQWJdzDMwDpUn7Uz/N5WMEn7ZlqF
 0Vb23hGg1TyDK2N3Yb23L8eahbKr77dX7Uei4zMEyEurSApH8ZOvF2y
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the build with musl + clang >=15; musl doesn't define
PATH_MAX anywhere else, and clang >=15 doesn't allow implicit
declarations with >=c99. Without this, the build fails due to PATH_MAX
not being defined.

We could include limits.h from the libc, but AFAIK the libc doesn't
necessarily have to define PATH_MAX, so it's safer to just include
linux/limits.h

Fixes: 845f16976929 ("libtracefs: Add unit tests")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
 utest/tracefs-utest.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/utest/tracefs-utest.c b/utest/tracefs-utest.c
index 963fac7..70bcf3e 100644
--- a/utest/tracefs-utest.c
+++ b/utest/tracefs-utest.c
@@ -16,6 +16,8 @@
 #include <kbuffer.h>
 #include <pthread.h>
 
+#include <linux/limits.h>
+
 #include <sys/mount.h>
 #include <sys/syscall.h>
 

-- 
2.43.0

