From: Chuan Liu <chuan.liu@amlogic.com>
Date: Fri, 11 Sep 2026 16:28:29 +0800
Subject: [PATCH 02/10] soc: amlogic: clk-measure: Support more measurement
 channels
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260911-more-socs-to-support-clk_measure-v1-2-940e269aa52f@amlogic.com>
References: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
In-Reply-To: <20260911-more-socs-to-support-clk_measure-v1-0-940e269aa52f@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789115329; l=1344;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=e2ydz5bLAgoXoKx1id6ARA1Qq/OeV3kWw0wR36wz9Ks=;
 b=Ni8daolTgIdg3jAm0A8kb0WCYbrmYnKh/C3NyycRuAnk8bFEMRQ6GS22kUNk1VOvJlgWA3y18
 cdffAlfZX26DHdr5MIXWfOtqEv7rTZiJaU19Ci0uE2qA1MwYsQf5+7n
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On S4 and C3, as well as later SoCs, the clk-measure IP expands the
number of supported measurement channels from 128 to 256. Accordingly,
the MSR_CLK_SRC field in the register is extended from 7 bits to 8 bits.

To support both the old and new implementations, the driver now
uniformly defines the valid MSR_CLK_SRC field as bits[27:20].

For SoCs where MSR_CLK_SRC is only 7 bits wide, the driver never sets
bit27, and on those SoCs bit27 is read-only. Therefore, using
bits[27:20] as the unified field definition does not introduce any
behavioral change or compatibility issue for existing SoCs.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
 drivers/soc/amlogic/meson-clk-measure.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/soc/amlogic/meson-clk-measure.c b/drivers/soc/amlogic/meson-clk-measure.c
index 8a1a9fed0e74..0d4ba2555d17 100644
--- a/drivers/soc/amlogic/meson-clk-measure.c
+++ b/drivers/soc/amlogic/meson-clk-measure.c
@@ -20,7 +20,7 @@ static DEFINE_MUTEX(measure_lock);
 #define MSR_CONT		BIT(17) /* continuous measurement */
 #define MSR_INTR		BIT(18) /* interrupts */
 #define MSR_RUN			BIT(19)
-#define MSR_CLK_SRC		GENMASK(26, 20)
+#define MSR_CLK_SRC		GENMASK(27, 20)
 #define MSR_BUSY		BIT(31)
 
 #define MSR_VAL_MASK		GENMASK(15, 0)

-- 
2.42.0

