From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 22 Feb 2024 11:12:45 +0100
Subject: [PATCH v2 2/3] utest/tracefs-utest: define _LARGEFILE64_SOURCE
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-utest-fixes-v2-2-ba9cd06b41d3@gmail.com>
References: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
In-Reply-To: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708596765; l=712;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=5SeXhPMSZNf3r3OXzTkrJzWyI2EtopiLnN2OK4A1N2s=;
 b=64d3NsTY9uZkTKjNRXuCH/UjaS+3LLBZFfwpz4dJaSHKipbeqWnQdLSaxDl0Pi7P6LfD5pBuK
 MsTpcC1ft6KDINRcQE7QHGrv1cvXMxL6UxQld66CAS9BCfEcBhl68Vb
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the build with musl + clang >=15; musl doesn't declare
lseek64() otherwise, and clang >=15 doesn't allow implicit declarations.

Fixes: 0f45e68cb04a ("libtracefs: Add unit tests for tracefs_cpu functions")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
 utest/tracefs-utest.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/utest/tracefs-utest.c b/utest/tracefs-utest.c
index 70bcf3e..224903b 100644
--- a/utest/tracefs-utest.c
+++ b/utest/tracefs-utest.c
@@ -3,6 +3,8 @@
  * Copyright (C) 2020, VMware, Tzvetomir Stoyanov <tz.stoyanov@gmail.com>
  *
  */
+#define _LARGEFILE64_SOURCE
+
 #include <stdio.h>
 #include <stdlib.h>
 #include <sys/stat.h>

-- 
2.43.0

