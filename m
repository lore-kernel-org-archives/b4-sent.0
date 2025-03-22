From: Hans-Frieder Vogt <hfdevel@gmx.net>
Date: Sat, 22 Mar 2025 11:45:54 +0100
Subject: [PATCH net-next v7 3/7] net: phy: aquantia: search for
 firmware-name in fwnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250322-tn9510-v3a-v7-3-672a9a3d8628@gmx.net>
References: <20250322-tn9510-v3a-v7-0-672a9a3d8628@gmx.net>
In-Reply-To: <20250322-tn9510-v3a-v7-0-672a9a3d8628@gmx.net>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 FUJITA Tomonori <fujita.tomonori@gmail.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hans-Frieder Vogt <hfdevel@gmx.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1742640367; l=1169;
 i=hfdevel@gmx.net; s=20240915; h=from:subject:message-id;
 bh=0zRi7Vk41IU72s/8DzrXAvCvexTz79in+5DW1aumMeg=;
 b=sSuPYpE50VbUFZaI7BYuD57IHP6bJEcMIOy+tTBQ2MO78IvnFAjXubb9ejGSMd4ugpSBtfY5A
 3OSA+wRq3s9DnQhxtHyRfXD8sWBdAxpFVEkR4y8pSEAnevNh/vCQfnU
X-Developer-Key: i=hfdevel@gmx.net; a=ed25519;
 pk=s3DJ3DFe6BJDRAcnd7VGvvwPXcLgV8mrfbpt8B9coRc=
X-Endpoint-Received: by B4 Relay for hfdevel@gmx.net/20240915 with auth_id=209
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Allow the firmware name of an Aquantia PHY alternatively be provided by the
property "firmware-name" of a swnode. This software node may be provided by
the MAC or MDIO driver.

Signed-off-by: Hans-Frieder Vogt <hfdevel@gmx.net>
Reviewed-by: Andrew Lunn <andrew@lunn.ch>
---
 drivers/net/phy/aquantia/aquantia_firmware.c | 7 ++++---
 1 file changed, 4 insertions(+), 3 deletions(-)

diff --git a/drivers/net/phy/aquantia/aquantia_firmware.c b/drivers/net/phy/aquantia/aquantia_firmware.c
index dab3af80593f51ff6dc670dfb54ae358c2458c40..bbbcc9736b00e1cfa193f4398889a4c172ca27a4 100644
--- a/drivers/net/phy/aquantia/aquantia_firmware.c
+++ b/drivers/net/phy/aquantia/aquantia_firmware.c
@@ -328,10 +328,11 @@ static int aqr_firmware_load_fs(struct phy_device *phydev)
 	const char *fw_name;
 	int ret;
 
-	ret = of_property_read_string(dev->of_node, "firmware-name",
-				      &fw_name);
-	if (ret)
+	ret = device_property_read_string(dev, "firmware-name", &fw_name);
+	if (ret) {
+		phydev_err(phydev, "failed to read firmware-name: %d\n", ret);
 		return ret;
+	}
 
 	ret = request_firmware(&fw, fw_name, dev);
 	if (ret) {

-- 
2.47.2

