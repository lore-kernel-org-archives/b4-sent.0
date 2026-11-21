From: =?utf-8?q?Omar_Yi=C4=9Fitcan_Meng=C3=BC?= <menguomary@gmail.com>
Date: Sun, 22 Nov 2026 00:34:01 +0300
Subject: [PATCH] staging: most: dim2: remove unused sysfs.h and struct
 medialb_bus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-dim2-remove-unused-sysfs-h-v1-1-369ee2d0e438@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAA/yXMQQrCMBAF0KuEWXfADCIlVxEXNfNrR2gqGVOU0
 ruLunybt5GjGpxS2KhiNbelUAqxC5SnodzAppQCyUFOMYqw2ixcMS8ruJXmUPa3j84Ty3HIuVc
 otKcu0KNitNcvP1/+9na9Iz+/I+37B8qm7SN+AAAA
X-Change-ID: 20261122-dim2-remove-unused-sysfs-h-24acc8deded8
To: Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Christian Gromm <christian.gromm@microchip.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-kernel@vger.kernel.org, linux-staging@lists.linux.dev, 
 =?utf-8?q?Omar_Yi=C4=9Fitcan_Meng=C3=BC?= <menguomary@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795296841; l=2263;
 i=menguomary@gmail.com; s=20261121; h=from:subject:message-id;
 bh=demJ0NhC0KXqJH5CiCWgQMWo8L6R/Fj2vHfQlkO0inU=;
 b=kZJ8PxJvM/fRbHAkjbJdCSpO6E0LJc4Ah9PRNio4BnnHpz5oWT+yGsiHSV8ukRpVHPFXxI71D
 HlvlqhR+ck+AGdkGkR3SL4cf4wz9Zw6mkE4LL4Mz9/Arjpi1rtV17Wo
X-Developer-Key: i=menguomary@gmail.com; a=ed25519;
 pk=dgRbAFBMBZdJfvBTw9RBcE3WxXn6Yt7GOZFPRpQqpkY=
X-Endpoint-Received: by B4 Relay for menguomary@gmail.com/20261121 with auth_id=1595
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 4d5f022f3a66 ("staging: most: remove proprietary kobjects")
stopped using struct medialb_bus and replaced it with struct device,
but left the unused bus member in struct dim2_hdm and its definition
in sysfs.h behind.

Later, commit 2ab189164056 ("staging: most: dim2: do not double-register
the same device") removed sysfs.c and all remaining declarations from
sysfs.h, leaving sysfs.h with only the unused struct medialb_bus
definition.

Remove the unused bus member from struct dim2_hdm, drop the sysfs.h
include from dim2.c, and delete sysfs.h.

Signed-off-by: Omar Yiğitcan Mengü <menguomary@gmail.com>
---
 drivers/staging/most/dim2/dim2.c  |  2 --
 drivers/staging/most/dim2/sysfs.h | 19 -------------------
 2 files changed, 21 deletions(-)

diff --git a/drivers/staging/most/dim2/dim2.c b/drivers/staging/most/dim2/dim2.c
index 0e2512d16..06d5f17e0 100644
--- a/drivers/staging/most/dim2/dim2.c
+++ b/drivers/staging/most/dim2/dim2.c
@@ -20,7 +20,6 @@
 #include <linux/of.h>
 #include "hal.h"
 #include "errors.h"
-#include "sysfs.h"
 
 #define DMA_CHANNELS (32 - 1)  /* channel 0 is a system channel */
 
@@ -93,7 +92,6 @@ struct dim2_hdm {
 	unsigned char mac_addrs[6];
 	unsigned char link_state;
 	int atx_idx;
-	struct medialb_bus bus;
 	void (*on_netinfo)(struct most_interface *most_iface,
 			   unsigned char link_state, unsigned char *addrs);
 	void (*disable_platform)(struct platform_device *pdev);
diff --git a/drivers/staging/most/dim2/sysfs.h b/drivers/staging/most/dim2/sysfs.h
deleted file mode 100644
index 60405cd47..000000000
--- a/drivers/staging/most/dim2/sysfs.h
+++ /dev/null
@@ -1,19 +0,0 @@
-/* SPDX-License-Identifier: GPL-2.0 */
-/*
- * MediaLB sysfs information
- *
- * Copyright (C) 2015, Microchip Technology Germany II GmbH & Co. KG
- */
-
-/* Author: Andrey Shvetsov <andrey.shvetsov@k2l.de> */
-
-#ifndef DIM2_SYSFS_H
-#define	DIM2_SYSFS_H
-
-#include <linux/kobject.h>
-
-struct medialb_bus {
-	struct kobject kobj_group;
-};
-
-#endif	/* DIM2_SYSFS_H */

---
base-commit: 4f618bb81ea5403c0922bda75411c4669b8a4641
change-id: 20261122-dim2-remove-unused-sysfs-h-24acc8deded8

Best regards,
--  
Omar Yiğitcan Mengü <menguomary@gmail.com>

