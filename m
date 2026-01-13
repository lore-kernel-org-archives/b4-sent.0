From: Rudraksha Gupta <guptarud@gmail.com>
Date: Mon, 12 Jan 2026 22:42:25 -0800
Subject: [PATCH 2/3] mfd: rk8xx-core: Configure `rk808-clkout2` function
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260112-ppp_connectivity-v1-2-284d6e83b212@gmail.com>
References: <20260112-ppp_connectivity-v1-0-284d6e83b212@gmail.com>
In-Reply-To: <20260112-ppp_connectivity-v1-0-284d6e83b212@gmail.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Lee Jones <lee@kernel.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-rockchip@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 =?utf-8?q?Kamil_Trzci=C5=84ski?= <ayufan@ayufan.eu>, 
 Martijn Braam <martijn@brixit.nl>, Ondrej Jirman <megi@xff.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768286545; l=1504;
 i=guptarud@gmail.com; s=20240916; h=from:subject:message-id;
 bh=ySfNjI6t8Mnuq2/ifE0ZjoFXQgOPGkiy/R6d0iMEMgg=;
 b=RYIUKOvuwbl5bNrcjJRBKCvN4zR/uEWENYzfyCgtOLKTGNhHcD6wgIPpYaUDMVU+2EzN4GNLR
 mVb3zHI1nmvCzdRUtIDJ4jN4KmqqTvgyiFD50giORdpGvKrZrMSfPzG
X-Developer-Key: i=guptarud@gmail.com; a=ed25519;
 pk=ETrudRugWAtOpr0OhRiheQ1lXM4Kk4KGFnBySlKDi2I=
X-Endpoint-Received: by B4 Relay for guptarud@gmail.com/20240916 with auth_id=211
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Kamil Trzciński <ayufan@ayufan.eu>

While the Wifi and Bluetooth chip are defined in the Pinephone Pro's
DTS, it actually isn't able to be used. Let's define rk808-clkout2 so
that userspace can actually interact with Wifi and Bluetooth

Co-developed-by: Martijn Braam <martijn@brixit.nl>
Signed-off-by: Martijn Braam <martijn@brixit.nl>
Signed-off-by: Kamil Trzciński <ayufan@ayufan.eu>
Signed-off-by: Ondrej Jirman <megi@xff.cz>
Signed-off-by: Rudraksha Gupta <guptarud@gmail.com>
---
 drivers/mfd/rk8xx-core.c  | 1 +
 include/linux/mfd/rk808.h | 2 ++
 2 files changed, 3 insertions(+)

diff --git a/drivers/mfd/rk8xx-core.c b/drivers/mfd/rk8xx-core.c
index def4587fdfb8..602218694334 100644
--- a/drivers/mfd/rk8xx-core.c
+++ b/drivers/mfd/rk8xx-core.c
@@ -282,6 +282,7 @@ static const struct rk808_reg_data rk818_pre_init_reg[] = {
 	{ RK818_H5V_EN_REG,	  BIT(0),	    RK818_H5V_EN },
 	{ RK808_VB_MON_REG,	  MASK_ALL,	    VB_LO_ACT |
 						    VB_LO_SEL_3500MV },
+	{ RK808_CLK32OUT_REG, CLK32KOUT2_FUNC_MASK, CLK32KOUT2_FUNC },
 };
 
 static const struct regmap_irq rk805_irqs[] = {
diff --git a/include/linux/mfd/rk808.h b/include/linux/mfd/rk808.h
index 28170ee08898..077fe2e15b78 100644
--- a/include/linux/mfd/rk808.h
+++ b/include/linux/mfd/rk808.h
@@ -934,6 +934,8 @@ enum rk806_dvs_mode {
 
 #define VOUT_LO_INT	BIT(0)
 #define CLK32KOUT2_EN	BIT(0)
+#define CLK32KOUT2_FUNC		(0 << 1)
+#define CLK32KOUT2_FUNC_MASK	BIT(1)
 
 #define TEMP105C			0x08
 #define TEMP115C			0x0c

-- 
2.52.0

