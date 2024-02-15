From: Miko Larsson <mikoxyzzz@gmail.com>
Date: Thu, 15 Feb 2024 10:02:43 +0100
Subject: [PATCH 3/3] utest/trace-utest: add missing include
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240215-utest-fixes-v1-3-24678d859de2@gmail.com>
References: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
In-Reply-To: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707987764; l=549;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=kXkgaZM5Vzaw8MUgARUr0Feh2OE7CWrfGiYcTXTyl/8=;
 b=P8Vq1ExOF+dEqttcdgMg92axx7De+HVFkNZDuJgY1lm0BBFbGKEMTneb4puXFXjE7386HCfRn
 jjK7X91ODFoBCbPLgIuKjBk+aQf3uuVUCv+9dSIydtQ2+OcECejOlZO
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fixes FTBFS with clang >=15

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

