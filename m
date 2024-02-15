From: Miko Larsson <mikoxyzzz@gmail.com>
Subject: [PATCH 0/3] utest: fix FTBFS with clang >=15
Date: Thu, 15 Feb 2024 10:02:40 +0100
Message-Id: <20240215-utest-fixes-v1-0-24678d859de2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADDTzWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0NT3dKS1OIS3bTMitRiXQtLY2ND06RUIyPTJCWgjoKiVLAEUEN0bG0
 tAE72LLtdAAAA
To: linux-trace-devel@vger.kernel.org
Cc: Miko Larsson <mikoxyzzz@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1707987764; l=666;
 i=mikoxyzzz@gmail.com; s=20240215; h=from:subject:message-id;
 bh=/rNiuekXqfH7463kjm5WZy3JG7cQy6DQQxjQ9sRgopQ=;
 b=dj4hWfMLYYUyytW96ax2d9b98e+2Jjnh1DiqPvWkK04jP06UVF93uxuJ+GGCNjzvXCjAha/cb
 wtv2XICWYcwCjxUI/YG8aLqm7M7G+XoQ5GPY2fqGvXpc5C3a4i+L8Mt
X-Developer-Key: i=mikoxyzzz@gmail.com; a=ed25519;
 pk=1WO6EuQa9ZdBA5vCl3bQNjIb6FdQDoTriJmTDrF5mFw=
X-Endpoint-Received: by B4 Relay for mikoxyzzz@gmail.com/20240215 with auth_id=130
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Clang 15 onwards defaults to -Werror=implicit-function-declaration,
which breaks the utest build. This series fixes that by simply adding
the missing include and define directives.

Signed-off-by: Miko Larsson <mikoxyzzz@gmail.com>
---
Miko Larsson (3):
      utest/tracefs-utest: add missing include
      utest/tracefs-utest: add missing define
      utest/trace-utest: add missing include

 utest/trace-utest.c   | 1 +
 utest/tracefs-utest.c | 4 ++++
 2 files changed, 5 insertions(+)
---
base-commit: 5f27b7f3fb7d88b29522baf3883cc0e2e28b1af0
change-id: 20240215-utest-fixes-893315be225b

Best regards,
-- 
Miko Larsson <mikoxyzzz@gmail.com>

