From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 15 Feb 2024 11:25:22 +0100
Subject: [PATCH] utest/trace-utest: add missing include
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240215-utest-fixes-v1-1-3cb7a281506d@gmail.com>
X-B4-Tracking: v=1; b=H4sIAJHmzWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0NT3dKS1OIS3bTMitRi3eQU05TkZONUC1PjJCWgjoKiVLAEUEN0bG0
 tAKdiTghdAAAA
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707992726; l=729;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=lRozkW2e+TwWY75PUiA6Ncrh0TqaO6YhzOmkHh7ZB6c=;
 b=3/Ej+t8RZLB+o+JKLMpMFM2iortKNbYah9XWTWd1CiJwTMkzqH5zYV1NHt/zCReS14+kC/xo/
 fipzNnVrxYrAfRl1QYLS8v51dqRnx4hSnNzrk/cyNF5PvmBlu6Nlm0e
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes FTBFS with clang >=15

Fixes: 58cbc1b2a84e ("libtraceevent: Add unit test framework for library commands")
Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
 utest/trace-utest.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/utest/trace-utest.c b/utest/trace-utest.c
index 1403c86..a26e42e 100644
--- a/utest/trace-utest.c
+++ b/utest/trace-utest.c
@@ -6,6 +6,7 @@
  *   Copyright (C) 2021, VMware, Steven Rostedt <rostedt@goodmis.org>
  *
  */
+#include <libgen.h>
 #include <stdio.h>
 #include <unistd.h>
 #include <getopt.h>

---
base-commit: 6f6d5802f31992e7527a4c32b43a32fda6bf6bdf
change-id: 20240215-utest-fixes-cd5dcc3e853b

Best regards,
-- 
Miko Larsson <mikoxyzzz@gmail.com>

