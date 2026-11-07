From: Roman Vivchar <rva333@protonmail.com>
Date: Sat, 07 Nov 2026 16:54:44 +0200
Subject: [PATCH v3 3/3] usb: mtu3: add mt6595 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-6595-mtu3-v3-3-f36bc569cb47@protonmail.com>
References: <20261107-6595-mtu3-v3-0-f36bc569cb47@protonmail.com>
In-Reply-To: <20261107-6595-mtu3-v3-0-f36bc569cb47@protonmail.com>
To: Chunfeng Yun <chunfeng.yun@mediatek.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-usb@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794063282; l=1155;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=MH/mAQtsGq6RAwp6c/enfc7ur+acQQpTl7FnupfzQkI=;
 b=mvwt455QhrE/7f4g4dyCBd2KF5jJ+28D7VdMketYUp6laKqvUH6dksPfr0Koand+BnCQYjGAp
 DOYS/KFdwz0DBrRoHo4fsg2KG5hNXj9JTWDpk/i7FsaDst2oWKKjdtL
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add a platform data for the MediaTek mt6595 SoC MTU3 IP block with a
quirk for single FIFO slot.

Reviewed-by: AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/usb/mtu3/mtu3_plat.c | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/drivers/usb/mtu3/mtu3_plat.c b/drivers/usb/mtu3/mtu3_plat.c
index bb67da4704b2..9d633695a9be 100644
--- a/drivers/usb/mtu3/mtu3_plat.c
+++ b/drivers/usb/mtu3/mtu3_plat.c
@@ -611,11 +611,16 @@ static const struct dev_pm_ops mtu3_pm_ops = {
 
 #define DEV_PM_OPS (IS_ENABLED(CONFIG_PM) ? &mtu3_pm_ops : NULL)
 
+static const struct mtu3_platform_data mt6595_platform_data = {
+	.fifo_single_slot = true,
+};
+
 static const struct mtu3_platform_data mt8173_platform_data = {
 	.fifo_single_slot = false,
 };
 
 static const struct of_device_id mtu3_of_match[] = {
+	{ .compatible = "mediatek,mt6595-mtu3", .data = &mt6595_platform_data },
 	{ .compatible = "mediatek,mt8173-mtu3", .data = &mt8173_platform_data },
 	{ .compatible = "mediatek,mtu3", .data = &mt8173_platform_data },
 	{},

-- 
2.56.0

