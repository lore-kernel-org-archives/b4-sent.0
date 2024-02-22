From: Miko Larsson <mikoxyzzz@gmail.com>
Subject: [PATCH v2 0/3] utest: fix build with musl + clang >=15
Date: Thu, 22 Feb 2024 11:12:43 +0100
Message-Id: <20240222-utest-fixes-v2-0-ba9cd06b41d3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABse12UC/22MQQ6CMBBFr0JmbU07UC2uvIdhAXSESYSatjYa0
 rtbWbt8/+e9DQJ5pgCXagNPiQO7tQAeKhjnfp1IsC0MKLGRqLR4RQpR3PlNQZi2rpUeCFEPUIy
 np/0owq0rPHOIzn/2eFK/9X8nKSEFNqezsUa3lvA6LT0/jqNboMs5fwFWCOQfpgAAAA==
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708596765; l=901;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=pf9GRBXf0zWEkISsxP/DHBNGtJ+jdtSV4tq+qMI8LGM=;
 b=SX0huGv671lRd1WtwcVr+j4+yIYmxOJ0fqSRb681X5sDzzl3GsD71Uf67TY3axSMZkvmVCaBZ
 51TWAOyLy9gBJqBwlnOaOwxxy139O0ZfdpvslbBk65DCsEJI4+YVFGG
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Clang 15 onwards defaults to -Werror=implicit-function-declaration
which, combined with musl not declaring all the stuff we need without
the missing includes and defines, breaks the utest build. This series
fixes thus by simply adding the missing stuff.

Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
Changes in v2:
- Better commit descriptions, messages
- Link to v1: https://lore.kernel.org/r/20240215-utest-fixes-v1-0-24678d859de2@gmail.com

---
Miko Larsson (3):
      utest/tracefs-utest: include linux/limits.h
      utest/tracefs-utest: define _LARGEFILE64_SOURCE
      utest/trace-utest: include libgen.h

 utest/trace-utest.c   | 1 +
 utest/tracefs-utest.c | 4 ++++
 2 files changed, 5 insertions(+)
---
base-commit: 5f27b7f3fb7d88b29522baf3883cc0e2e28b1af0
change-id: 20240215-utest-fixes-893315be225b

Best regards,
-- 
Miko Larsson <mikoxyzzz@gmail.com>

