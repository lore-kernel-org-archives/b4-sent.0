From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 22 Feb 2024 11:12:46 +0100
Subject: [PATCH v2 3/3] utest/trace-utest: include libgen.h
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240222-utest-fixes-v2-3-ba9cd06b41d3@gmail.com>
References: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
In-Reply-To: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708596765; l=667;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=EetEr7KQnL5UP3Nk+LwH32FOuETzJwv3l+Uu0BV2+ng=;
 b=ApgoaBoIwbpv0szrNeoC41jE5sAhyPiQTQK71d+DGhAgbbyYbSeVpJzQSiMQDRKAgAiUL/5Yz
 1sj8NL/YmR5CtOqz4xDsY4ROBeBSACZUEAvpvfWE+DHTOloiO/u55wL
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This fixes the build with musl + clang >=15; musl doesn't declare
basename() anywhere else, and clang >=15 doesn't allow implicit
declarations.

Fixes: 845f16976929 ("libtracefs: Add unit tests")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
 utest/trace-utest.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/utest/trace-utest.c b/utest/trace-utest.c
index 58d4d4e..39485a1 100644
--- a/utest/trace-utest.c
+++ b/utest/trace-utest.c
@@ -3,6 +3,7 @@
  * Copyright (C) 2020, VMware, Tzvetomir Stoyanov <tz.stoyanov@gmail.com>
  *
  */
+#include <libgen.h>
 #include <stdio.h>
 #include <unistd.h>
 #include <getopt.h>

-- 
2.43.0

