From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Fri, 19 Jul 2024 16:08:10 +0800
Subject: [PATCH v3 2/6] soc: amlogic: meson-gx-socinfo: add new SoCs id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240719-soc_info-v3-2-020a3b687c0c@amlogic.com>
References: <20240719-soc_info-v3-0-020a3b687c0c@amlogic.com>
In-Reply-To: <20240719-soc_info-v3-0-020a3b687c0c@amlogic.com>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721376490; l=1182;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=zRWWsMnyYjBcl83+I2nHF9NZDOoGs2C4FOAOFivyI1k=;
 b=2N3VqoSg90YHKRwkRLAuCyMLMMD4AtkI2P8zYR5Mxi8W0Kbw8U+ctTMenOiDH9TOh2XHWlVH/
 0EzzzrNYT0zD1VOsz+8/XcyUI0Qwn9riN54CXGVaOuKayNLqu1/hbEi
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new definition for Amlogi SoCs, include S4, C3, T7, A4, A5.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/soc/amlogic/meson-gx-socinfo.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/drivers/soc/amlogic/meson-gx-socinfo.c b/drivers/soc/amlogic/meson-gx-socinfo.c
index 8809a948201a..7549f1644e5e 100644
--- a/drivers/soc/amlogic/meson-gx-socinfo.c
+++ b/drivers/soc/amlogic/meson-gx-socinfo.c
@@ -41,6 +41,11 @@ static const struct meson_gx_soc_id {
 	{ "G12B", 0x29 },
 	{ "SM1", 0x2b },
 	{ "A1", 0x2c },
+	{ "T7", 0x36 },
+	{ "S4", 0x37 },
+	{ "A5", 0x3c },
+	{ "C3", 0x3d },
+	{ "A4", 0x40 },
 };
 
 static const struct meson_gx_package_id {
@@ -76,6 +81,11 @@ static const struct meson_gx_package_id {
 	{ "S905X3", 0x2b, 0x10, 0x3f },
 	{ "S905D3", 0x2b, 0x30, 0x3f },
 	{ "A113L", 0x2c, 0x0, 0xf8 },
+	{ "S805X2", 0x37, 0x2, 0xf },
+	{ "C308L", 0x3d, 0x1, 0xf },
+	{ "A311D2", 0x36, 0x1, 0xf },
+	{ "A113X2", 0x3c, 0x1, 0xf },
+	{ "A113L2", 0x40, 0x1, 0xf },
 };
 
 static inline unsigned int socinfo_to_major(u32 socinfo)

-- 
2.37.1

