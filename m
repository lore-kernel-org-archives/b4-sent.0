From: Satish Kharat <satishkh@cisco.com>
Date: Sat, 21 Feb 2026 10:16:59 -0800
Subject: [PATCH 1/2] net:ethernet:enic: add VIC subsystem ids
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260221-enic-cscwi36355-v1-1-5a01a6046d5e@cisco.com>
References: <20260221-enic-cscwi36355-v1-0-5a01a6046d5e@cisco.com>
In-Reply-To: <20260221-enic-cscwi36355-v1-0-5a01a6046d5e@cisco.com>
To: netdev@vger.kernel.org
Cc: Satish Kharat <satishkh@cisco.com>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771697893; l=2264;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=dmiiJ3fxTUP7u8ZrF0g2EZDSbfEDLnZtm8vLm5JCiQk=;
 b=4pUmsOqoXDGWoNIcqlH72YM9e9kxNZnNw+dF4HQ/XWKUcMDbKAbOrWEqIxXxUaKgKPEfG1EyP
 LGcEFrQTIFnB0LNvqqSy+qp6JQn6Y+NfcTqppJqYEAuBlGLnEkC4gsT
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add VIC subsystem id for 12xx, 13xx, 14xx and 15xxx series

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 drivers/net/ethernet/cisco/enic/enic.h | 39 ++++++++++++++++++++++++++++++++++
 1 file changed, 39 insertions(+)

diff --git a/drivers/net/ethernet/cisco/enic/enic.h b/drivers/net/ethernet/cisco/enic/enic.h
index 301b3f311..6959e85ab 100644
--- a/drivers/net/ethernet/cisco/enic/enic.h
+++ b/drivers/net/ethernet/cisco/enic/enic.h
@@ -22,6 +22,45 @@
 #define DRV_NAME		"enic"
 #define DRV_DESCRIPTION		"Cisco VIC Ethernet NIC Driver"
 
+#define PCI_SUBDEV_ID_CISCO_VIC_1225	0x085
+#define PCI_SUBDEV_ID_CISCO_VIC_1225T	0x0CE
+#define PCI_SUBDEV_ID_CISCO_VIC_1227	0x12E
+#define PCI_SUBDEV_ID_CISCO_VIC_1227T	0x139
+#define PCI_SUBDEV_ID_CISCO_VIC_1240	0x084
+#define PCI_SUBDEV_ID_CISCO_VIC_1280	0x04F
+#define PCI_SUBDEV_ID_CISCO_VIC_1285	0x0CD
+
+#define PCI_SUBDEV_ID_CISCO_VIC_1340	0x12C
+#define PCI_SUBDEV_ID_CISCO_VIC_1380	0x137
+#define PCI_SUBDEV_ID_CISCO_VIC_1385	0x14D
+#define PCI_SUBDEV_ID_CISCO_VIC_1387	0x15D
+
+#define PCI_SUBDEV_ID_CISCO_VIC_1440	0x0215
+#define PCI_SUBDEV_ID_CISCO_VIC_1455	0x0217
+#define PCI_SUBDEV_ID_CISCO_VIC_1457	0x0218
+#define PCI_SUBDEV_ID_CISCO_VIC_1467	0x02AF
+#define PCI_SUBDEV_ID_CISCO_VIC_1477	0x2B0
+#define PCI_SUBDEV_ID_CISCO_VIC_1480	0x0216
+#define PCI_SUBDEV_ID_CISCO_VIC_1485	0x0219
+#define PCI_SUBDEV_ID_CISCO_VIC_1487	0x021A
+#define PCI_SUBDEV_ID_CISCO_VIC_1495	0x024A
+#define PCI_SUBDEV_ID_CISCO_VIC_1497	0x024B
+#define PCI_SUBDEV_ID_CISCO_VIC_14425	0x02CF
+#define PCI_SUBDEV_ID_CISCO_VIC_14825	0x02D0
+
+#define PCI_SUBDEV_ID_CISCO_VIC_15230	0x02DF
+#define PCI_SUBDEV_ID_CISCO_VIC_15231	0x02DB
+#define PCI_SUBDEV_ID_CISCO_VIC_15235	0x02E4
+#define PCI_SUBDEV_ID_CISCO_VIC_15237	0x02F3
+#define PCI_SUBDEV_ID_CISCO_VIC_15238	0x02E8
+#define PCI_SUBDEV_ID_CISCO_VIC_15411	0x02DC
+#define PCI_SUBDEV_ID_CISCO_VIC_15412	0x02E2
+#define PCI_SUBDEV_ID_CISCO_VIC_15420	0x02DE
+#define PCI_SUBDEV_ID_CISCO_VIC_15422	0x02E1
+#define PCI_SUBDEV_ID_CISCO_VIC_15425	0x02F2
+#define PCI_SUBDEV_ID_CISCO_VIC_15427	0x02E0
+#define PCI_SUBDEV_ID_CISCO_VIC_15428	0x02DD
+
 #define ENIC_BARS_MAX		6
 
 #define ENIC_WQ_MAX		256

-- 
2.43.0

