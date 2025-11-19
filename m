From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Wed, 19 Nov 2025 10:52:23 +0800
Subject: [PATCH v3 2/5] soc: amlogic: meson-gx-socinfo: add new SoCs id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251119-soc-info-s6-s7-s7d-v3-2-1764c1995c04@amlogic.com>
References: <20251119-soc-info-s6-s7-s7d-v3-0-1764c1995c04@amlogic.com>
In-Reply-To: <20251119-soc-info-s6-s7-s7d-v3-0-1764c1995c04@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763520743; l=1131;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=2Mf1Qm+uRzCORwHeNC32iVQnPUYJm9R5423gGpFP26o=;
 b=LvDbdITIaIPRQ5mkhRzLzxcmSAM22ARk2rlCXtaPf8xd7zO3rkzZE2v55YVNg8hBIrfx1f6wJ
 HSErg+4k9FnDKMMhmDqVwaICHoPlWkm1hBxG5HYYDtT6/ZWlldZXryj
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new definition for Amlogic SoCs, include S6, S7, S7D.

Reviewed-by: Neil Armstrong <neil.armstrong@linaro.org>
Reviewed-by: Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 drivers/soc/amlogic/meson-gx-socinfo.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/drivers/soc/amlogic/meson-gx-socinfo.c b/drivers/soc/amlogic/meson-gx-socinfo.c
index 7549f1644e5e..2a54ca43cd13 100644
--- a/drivers/soc/amlogic/meson-gx-socinfo.c
+++ b/drivers/soc/amlogic/meson-gx-socinfo.c
@@ -46,6 +46,9 @@ static const struct meson_gx_soc_id {
 	{ "A5", 0x3c },
 	{ "C3", 0x3d },
 	{ "A4", 0x40 },
+	{ "S7", 0x46 },
+	{ "S7D", 0x47 },
+	{ "S6", 0x48 },
 };
 
 static const struct meson_gx_package_id {
@@ -86,6 +89,9 @@ static const struct meson_gx_package_id {
 	{ "A311D2", 0x36, 0x1, 0xf },
 	{ "A113X2", 0x3c, 0x1, 0xf },
 	{ "A113L2", 0x40, 0x1, 0xf },
+	{ "S805X3", 0x46, 0x3, 0xf },
+	{ "S905X5M", 0x47, 0x1, 0xf },
+	{ "S905X5", 0x48, 0x1, 0xf },
 };
 
 static inline unsigned int socinfo_to_major(u32 socinfo)

-- 
2.37.1

