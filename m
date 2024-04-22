From: Kelvin Zhang <kelvin.zhang@amlogic.com>
Date: Mon, 22 Apr 2024 19:11:44 +0800
Subject: [PATCH v2 2/3] reset: reset-meson: Add support for Amlogic T7 SoC
 reset controller
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240422-t7-reset-v2-2-cb82271d3296@amlogic.com>
References: <20240422-t7-reset-v2-0-cb82271d3296@amlogic.com>
In-Reply-To: <20240422-t7-reset-v2-0-cb82271d3296@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713784331; l=1542;
 i=kelvin.zhang@amlogic.com; s=20240329; h=from:subject:message-id;
 bh=V9Mku9OeTyU3lnGbQaD9sh0OS9qpGjOnwcE8yjtQxFM=;
 b=VDZujYI/hY37dRyDX1UhtvU4NDwHA/K1jjD+Rm4uyzS+R08RTkxnMoRisdtTCSgF5kU2LT9tn
 Lb/NQJbYztNCbz+HGSyUwV67i0NL1aV0Q/9tbcC/+wekdfMLHnPCALG
X-Developer-Key: i=kelvin.zhang@amlogic.com; a=ed25519;
 pk=pgnle7HTNvnNTcOoGejvtTC7BJT30HUNXfMHRRXSylI=
X-Endpoint-Received: by B4 Relay for kelvin.zhang@amlogic.com/20240329 with auth_id=148
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Zelong Dong <zelong.dong@amlogic.com>

There are 7 sets of Reset Source in Amlogic T7 SoC reset controller,
and the offset between base and level registers is 0x40.
Add a new compatible string and struct meson_reset_param to support
the reset controller on T7 SoC.

Signed-off-by: Zelong Dong <zelong.dong@amlogic.com>
Signed-off-by: Kelvin Zhang <kelvin.zhang@amlogic.com>
Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
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

