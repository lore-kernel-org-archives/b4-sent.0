From: Joel Selvaraj <foss@joelselvaraj.com>
Date: Wed, 09 Sep 2026 01:12:02 -0700
Subject: [PATCH 4/4] drm/panel: ebbg-ft8719: update Joel Selvaraj's email
 address
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260909-update-email-address-v1-4-94a240f9469e@joelselvaraj.com>
References: <20260909-update-email-address-v1-0-94a240f9469e@joelselvaraj.com>
In-Reply-To: <20260909-update-email-address-v1-0-94a240f9469e@joelselvaraj.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, Joel Selvaraj <foss@joelselvaraj.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788941524; l=1165;
 i=foss@joelselvaraj.com; s=20260909; h=from:subject:message-id;
 bh=vsAeeSW3w+ssvIy6gSDQz4fsGrrch3NZw9153qCisHI=;
 b=tt3Ct6OmTKkCdgyfIorTs6yKB7jYvq4ymidkt9KLqpjcins4+v5pPR2dYqnRxHSfVt+UIZ7sg
 BRK4cliA86gB1WM23XgL7ah9gnKg+jKcUSHHjUHT0QMK4yrhKa5sduy
X-Developer-Key: i=foss@joelselvaraj.com; a=ed25519;
 pk=UUJ1v4UQJ/nljqj3NjsWt5H4mphWQ7etpQ4Z7JiR2yo=
X-Endpoint-Received: by B4 Relay for foss@joelselvaraj.com/20260909 with auth_id=1018
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

My jsfamily.in address is no longer active, switch to my current one.

Signed-off-by: Joel Selvaraj <foss@joelselvaraj.com>
---
 drivers/gpu/drm/panel/panel-ebbg-ft8719.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
index fb9f9f42be4f2..5ee8b52962847 100644
--- a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
+++ b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
@@ -1,6 +1,6 @@
 // SPDX-License-Identifier: GPL-2.0-only
 /*
- * Copyright (c) 2022 Joel Selvaraj <jo@jsfamily.in>
+ * Copyright (c) 2022 Joel Selvaraj <foss@joelselvaraj.com>
  * Generated with linux-mdss-dsi-panel-driver-generator from vendor device tree:
  * Copyright (c) 2013, The Linux Foundation. All rights reserved.
  */
@@ -242,6 +242,6 @@ static struct mipi_dsi_driver ebbg_ft8719_driver = {
 };
 module_mipi_dsi_driver(ebbg_ft8719_driver);
 
-MODULE_AUTHOR("Joel Selvaraj <jo@jsfamily.in>");
+MODULE_AUTHOR("Joel Selvaraj <foss@joelselvaraj.com>");
 MODULE_DESCRIPTION("DRM driver for EBBG FT8719 video dsi panel");
 MODULE_LICENSE("GPL v2");

-- 
2.55.0

