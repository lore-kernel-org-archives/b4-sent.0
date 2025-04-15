From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 15 Apr 2025 15:49:20 +0100
Subject: [PATCH v2 04/17] mfd: adp5585: make use of MFD_CELL_NAME()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250415-dev-adp5589-fw-v2-4-3a799c3ed812@analog.com>
References: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
In-Reply-To: <20250415-dev-adp5589-fw-v2-0-3a799c3ed812@analog.com>
To: linux-gpio@vger.kernel.org, linux-pwm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-input@vger.kernel.org
Cc: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <ukleinek@kernel.org>, 
 Linus Walleij <linus.walleij@linaro.org>, 
 Bartosz Golaszewski <brgl@bgdev.pl>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Laurent Pinchart <laurent.pinchart@ideasonboard.com>, 
 Liu Ying <victor.liu@nxp.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744728559; l=932;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=0kJzqnAeuAQSRegsuk2cy/H4KUD6hhlPLmzzHmhsyqM=;
 b=ZzLThclVm012R6w/bEHxMcSLg3xSeVTVE4K+rhb0ILpfrjLNajWUJ//2HRL1Ej5pWfVdxuB5R
 almo/mWfewjCfGlebBOA1b9iCBi+ne1K8xj+Z3yygSXfxiIYqaQ8CEy
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use the helper macro. No functional change intended...

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
 drivers/mfd/adp5585.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/drivers/mfd/adp5585.c b/drivers/mfd/adp5585.c
index f17b5f2474cac6a403556694066f438288264a49..fafe3ad93ea196e1eb8e79fecba58f36f12167eb 100644
--- a/drivers/mfd/adp5585.c
+++ b/drivers/mfd/adp5585.c
@@ -4,6 +4,7 @@
  *
  * Copyright 2022 NXP
  * Copyright 2024 Ideas on Board Oy
+ * Copyright 2025 Analog Devices Inc.
  */
 
 #include <linux/array_size.h>
@@ -18,8 +19,10 @@
 #include <linux/types.h>
 
 static const struct mfd_cell adp5585_devs[] = {
-	{ .name = "adp5585-gpio", },
-	{ .name = "adp5585-pwm", },
+	MFD_CELL_NAME("adp5585-keys"),
+	MFD_CELL_NAME("adp5585-gpio"),
+	MFD_CELL_NAME("adp5585-pwm"),
+
 };
 
 static const struct regmap_range adp5585_volatile_ranges[] = {

-- 
2.49.0

