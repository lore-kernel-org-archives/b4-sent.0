From: Yang Xiwen <forbidden405@outlook.com>
Date: Thu, 01 Feb 2024 21:16:08 +0800
Subject: [PATCH 1/3] phy: add generic_setup(shutdown)_phy_bulk()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240201-ehci-v1-1-bb506cb0f64d@outlook.com>
References: <20240201-ehci-v1-0-bb506cb0f64d@outlook.com>
In-Reply-To: <20240201-ehci-v1-0-bb506cb0f64d@outlook.com>
To: Tom Rini <trini@konsulko.com>, Simon Glass <sjg@chromium.org>, 
 Marek Vasut <marex@denx.de>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1706793368; l=3077;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=MQ/Dd5vqnZwQ/TgBb7U0sIhViteC8bd5Xlg1UEte2jM=;
 b=8AB5ofRwZWz2Zi6goOtETmgPOKNmP008oiOFlhBwrKzsXFX8oeFha0eqe52b9nfENiRDfGPzi
 LYWLyLR4VxcAkVT3zjDd2UQY4hF3CiGedERKcMUJK4i4sh780H0iqxq
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

They are the bulk version of generic_setup(shutdown)_phy().

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 drivers/phy/phy-uclass.c | 33 +++++++++++++++++++++++++++++++++
 include/generic-phy.h    | 29 +++++++++++++++++++++++++++++
 2 files changed, 62 insertions(+)

diff --git a/drivers/phy/phy-uclass.c b/drivers/phy/phy-uclass.c
index 0dcfe258bc..d50ebbe3a0 100644
--- a/drivers/phy/phy-uclass.c
+++ b/drivers/phy/phy-uclass.c
@@ -528,6 +528,28 @@ int generic_setup_phy(struct udevice *dev, struct phy *phy, int index)
 	return ret;
 }
 
+int generic_setup_phy_bulk(struct udevice *dev, struct phy_bulk *bulk)
+{
+	struct phy *phys = bulk->phys;
+	int i, ret;
+
+	for (i = 0; i < bulk->count; i++) {
+		ret = generic_setup_phy(dev, &phys[i], i);
+		if (ret) {
+			pr_err("Can't setup PHY%d\n", i);
+			goto phys_setup_err;
+		}
+	}
+
+	return 0;
+
+phys_setup_err:
+	for (; i > 0; i--)
+		generic_shutdown_phy(&phys[i - 1]);
+
+	return ret;
+}
+
 int generic_shutdown_phy(struct phy *phy)
 {
 	int ret;
@@ -542,6 +564,17 @@ int generic_shutdown_phy(struct phy *phy)
 	return generic_phy_exit(phy);
 }
 
+int generic_shutdown_phy_bulk(struct phy_bulk *bulk)
+{
+	struct phy *phys = bulk->phys;
+	int i, ret = 0;
+
+	for (i = 0; i < bulk->count; i++)
+		ret |= generic_shutdown_phy(&phys[i]);
+
+	return ret;
+}
+
 UCLASS_DRIVER(phy) = {
 	.id		= UCLASS_PHY,
 	.name		= "phy",
diff --git a/include/generic-phy.h b/include/generic-phy.h
index eaab749166..2d1bf7c1ea 100644
--- a/include/generic-phy.h
+++ b/include/generic-phy.h
@@ -420,6 +420,16 @@ int generic_phy_power_off_bulk(struct phy_bulk *bulk);
  */
 int generic_setup_phy(struct udevice *dev, struct phy *phy, int index);
 
+/**
+ * generic_setup_phy() - Get, initialize and power on all phys in a phy bulk.
+ *
+ * @dev:	The consumer device.
+ * @bulk:	A pointer to the PHY bulk
+ *
+ * Return: 0 if OK, or negative error code.
+ */
+int generic_setup_phy_bulk(struct udevice *dev, struct phy_bulk *bulk);
+
 /**
  * generic_shutdown_phy() - Power off and de-initialize phy.
  *
@@ -429,6 +439,15 @@ int generic_setup_phy(struct udevice *dev, struct phy *phy, int index);
  */
 int generic_shutdown_phy(struct phy *phy);
 
+/**
+ * generic_shutdown_phy_bulk() - Power off and de-initialize all phys in a phy bulk.
+ *
+ * @bulk:	A pointer to the PHY bulk.
+ *
+ * Return: 0 if OK, or negative error code.
+ */
+int generic_shutdown_phy_bulk(struct phy_bulk *bulk);
+
 #else /* CONFIG_PHY */
 
 static inline int generic_phy_init(struct phy *phy)
@@ -514,11 +533,21 @@ static inline int generic_setup_phy(struct udevice *dev, struct phy *phy, int in
 	return 0;
 }
 
+static inline int generic_setup_phy_bulk(struct udevice *dev, struct phy_bulk *bulk)
+{
+	return 0;
+}
+
 static inline int generic_shutdown_phy(struct phy *phy)
 {
 	return 0;
 }
 
+static inline int generic_shutdown_phy_bulk(struct phy_bulk *bulk)
+{
+	return 0;
+}
+
 #endif /* CONFIG_PHY */
 
 /**

-- 
2.43.0

