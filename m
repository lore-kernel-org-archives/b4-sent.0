From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Fri, 29 Mar 2024 17:17:14 +0800
Subject: [PATCH 2/3] reset: reset-meson: add support for Amlogic T7 SoC
 Reset Controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240329-t7-reset-v1-2-4c6e2e68359e@amlogic.com>
References: <20240329-t7-reset-v1-0-4c6e2e68359e@amlogic.com>
In-Reply-To: <20240329-t7-reset-v1-0-4c6e2e68359e@amlogic.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Zelong Dong <zelong.dong@amlogic.com>, 
 Kelvin Zhang <kelvin.zhang@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1711703853; l=1485;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=4b5hJs6BojBwxeqHYbAP2s8Gj7Cc9H0Mgr5d5A9mC30=;
 b=gqs56u0cQ7PfE8Ihc4OxU0xkuogLNMu6dXnKoh4cnJadFPaUm10p+kwp+RuMafudpRJ4EbMKV
 2LSb7zLlIKLCu3X5UMYNahpJ8jZZw0xMPlyVmw94qAc2JiT4+XBlc6H
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zelong Dong <zelong.dong@amlogic.com>

There are 7 sets of Reset Source in Amlogic T7 SoC Reset Controller,
and the offset between base and level registers is 0x40.
Add a new compatible string and struct meson_reset_param to support
the reset controller on T7 SoC.

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
---
 drivers/reset/reset-meson.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/reset/reset-meson.c b/drivers/reset/reset-meson.c
index f78be97898bc..1e9fca3e30e8 100644
--- a/drivers/reset/reset-meson.c
+++ b/drivers/reset/reset-meson.c
@@ -102,6 +102,11 @@ static const struct meson_reset_param meson_s4_param = {
 	.level_offset	= 0x40,
 };
 
+static const struct meson_reset_param t7_param = {
+	.reg_count      = 7,
+	.level_offset   = 0x40,
+};
+
 static const struct of_device_id meson_reset_dt_ids[] = {
 	 { .compatible = "amlogic,meson8b-reset",    .data = &meson8b_param},
 	 { .compatible = "amlogic,meson-gxbb-reset", .data = &meson8b_param},
@@ -109,6 +114,7 @@ static const struct of_device_id meson_reset_dt_ids[] = {
 	 { .compatible = "amlogic,meson-a1-reset",   .data = &meson_a1_param},
 	 { .compatible = "amlogic,meson-s4-reset",   .data = &meson_s4_param},
 	 { .compatible = "amlogic,c3-reset",   .data = &meson_s4_param},
+	 { .compatible = "amlogic,t7-reset",   .data = &t7_param},
 	 { /* sentinel */ },
 };
 MODULE_DEVICE_TABLE(of, meson_reset_dt_ids);

-- 
2.37.1

