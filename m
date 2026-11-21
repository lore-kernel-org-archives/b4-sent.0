From: Roman Vivchar <rva333@protonmail.com>
Date: Sat, 21 Nov 2026 18:20:20 +0200
Subject: [PATCH] i2c: mediatek: fix probe when vbus supply exists in
 subnode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261121-6768-i2c-v1-1-98d51691fd8d@protonmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMyw5AMBCF4VeRWWvSdjHKq4hFL4OxQFpEIt5ds
 fyS/5wLEkWmBE1xQaSDEy9zhioL8KOdBxIcskFLjUppJbBCI1h74WxNQZoejUXI+Rqp5/O7arv
 faXcT+e3dw30/VVDJVGwAAAA=
X-Change-ID: 20261121-6768-i2c-ba9ed08f68a6
To: Qii Wang <qii.wang@mediatek.com>, Andi Shyti <andi.shyti@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Hsin-Yi Wang <hsinyi@chromium.org>, Wolfram Sang <wsa@kernel.org>
Cc: linux-i2c@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 stable@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795278019; l=2465;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=YhzKgoIIxqqoXlohk7kgtxKoK2RDTSFs2xMuyiqhthw=;
 b=fHfVZgp/Esnl363UzJY2eHoY6j4V+b5/DJ2MTSVJbV40V9QK1dWxF5n4nr8xnbkMsti/UTtIr
 DINIFR8GHXTAmAX8PP2F2yTuL3XeyhLXtFNoFZJhsh2mLh5FPICt19y
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 9029b9b2ae13 ("i2c: mediatek: mt65xx: add optional vbus-supply")
added an optional vbus-supply lookup in mtk_i2c_probe(). However, when
the i2c controller node itself doesn't define vbus-supply,
devm_regulator_get_optional() falls back to of_get_child_regulator(),
which recursively searches all children nodes for a matching vbus-supply
property.

If a device on the i2c bus (such as a USB-C connector) defines
vbus-supply, the i2c controller mistakenly binds to that regulator.
When that regulator is provided by another device on the same i2c bus,
probe fails permanently with a circular -EPROBE_DEFER dependency:

For example:
&i2c7 {
	charger@55 {
		smb1351_otg_vbus: usb-vbus { };
	};

	typec@60 {
		connector {
			vbus-supply = <&smb1351_otg_vbus>;
		};
	};
};

Ensure that i2c bus has its own regulator using of_property_present()
before calling devm_regulator_get_optional(). This resolves the issue
and makes both devices probe correctly.

Fixes: 9029b9b2ae13 ("i2c: mediatek: mt65xx: add optional vbus-supply")
Cc: stable@vger.kernel.org
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/i2c/busses/i2c-mt65xx.c | 14 ++++++++------
 1 file changed, 8 insertions(+), 6 deletions(-)

diff --git a/drivers/i2c/busses/i2c-mt65xx.c b/drivers/i2c/busses/i2c-mt65xx.c
index 45d0d7156d6e..042244c7d89d 100644
--- a/drivers/i2c/busses/i2c-mt65xx.c
+++ b/drivers/i2c/busses/i2c-mt65xx.c
@@ -1415,12 +1415,14 @@ static int mtk_i2c_probe(struct platform_device *pdev)
 	i2c->adap.quirks = i2c->dev_comp->quirks;
 	i2c->adap.timeout = 2 * HZ;
 	i2c->adap.retries = 1;
-	i2c->adap.bus_regulator = devm_regulator_get_optional(&pdev->dev, "vbus");
-	if (IS_ERR(i2c->adap.bus_regulator)) {
-		if (PTR_ERR(i2c->adap.bus_regulator) == -ENODEV)
-			i2c->adap.bus_regulator = NULL;
-		else
-			return PTR_ERR(i2c->adap.bus_regulator);
+	if (of_property_present(pdev->dev.of_node, "vbus-supply")) {
+		i2c->adap.bus_regulator = devm_regulator_get_optional(&pdev->dev, "vbus");
+		if (IS_ERR(i2c->adap.bus_regulator)) {
+			if (PTR_ERR(i2c->adap.bus_regulator) == -ENODEV)
+				i2c->adap.bus_regulator = NULL;
+			else
+				return PTR_ERR(i2c->adap.bus_regulator);
+		}
 	}
 
 	ret = mtk_i2c_parse_dt(pdev->dev.of_node, i2c);

---
base-commit: 909ef7a9a30fa139e69e555e3606680f5cca7726
change-id: 20261121-6768-i2c-ba9ed08f68a6

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

