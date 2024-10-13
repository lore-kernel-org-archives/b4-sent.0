From: "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>
Date: Sun, 13 Oct 2024 23:27:39 +0200
Subject: [PATCH v3 04/16] net: phy: Add helper for mapping RGMII link speed
 to clock rate
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241013-upstream_s32cc_gmac-v3-4-d84b5a67b930@oss.nxp.com>
References: <20241013-upstream_s32cc_gmac-v3-0-d84b5a67b930@oss.nxp.com>
In-Reply-To: <20241013-upstream_s32cc_gmac-v3-0-d84b5a67b930@oss.nxp.com>
To: Maxime Coquelin <mcoquelin.stm32@gmail.com>, 
 Alexandre Torgue <alexandre.torgue@foss.st.com>, 
 Jose Abreu <joabreu@synopsys.com>, "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Vinod Koul <vkoul@kernel.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>, Emil Renner Berthing <kernel@esmil.dk>, 
 Minda Chen <minda.chen@starfivetech.com>, 
 Nicolas Ferre <nicolas.ferre@microchip.com>, 
 Claudiu Beznea <claudiu.beznea@tuxon.dev>, 
 Iyappan Subramanian <iyappan@os.amperecomputing.com>, 
 Keyur Chudgar <keyur@os.amperecomputing.com>, 
 Quan Nguyen <quan@os.amperecomputing.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Giuseppe Cavallaro <peppe.cavallaro@st.com>
Cc: linux-stm32@st-md-mailman.stormreply.com, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 netdev@vger.kernel.org, linux-arm-msm@vger.kernel.org, imx@lists.linux.dev, 
 devicetree@vger.kernel.org, NXP S32 Linux Team <s32@nxp.com>, 
 "Jan Petrous (OSS)" <jan.petrous@oss.nxp.com>, 
 "Russell King (Oracle)" <rmk+kernel@armlinux.org.uk>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728854875; l=2138;
 i=jan.petrous@oss.nxp.com; s=20240922; h=from:subject:message-id;
 bh=DaDkzUPthYLXEW32SreKBO3MyQ9lanZalBFxpDCNQzE=;
 b=bo+RPMH3Mt3S1/zUl8ym396kld4wUMRFbTsLm5IgKWk0eKbfyTYScNWSGecqm9ZQqMjJk8ZEp
 qtga7k6oZDxDG2MG5OuboP6Z/O5hDkbWtDc3kFxhksvVJCx7PNcKAvX
X-Developer-Key: i=jan.petrous@oss.nxp.com; a=ed25519;
 pk=Ke3wwK7rb2Me9UQRf6vR8AsfJZfhTyoDaxkUCqmSWYY=
X-Endpoint-Received: by B4 Relay for jan.petrous@oss.nxp.com/20240922 with auth_id=217
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The helper rgmii_clock() implemented Russel's hint during stmmac
glue driver review:

  > We seem to have multiple cases of very similar logic in lots of stmmac
  > platform drivers, and I think it's about time we said no more to this.
  > So, what I think we should do is as follows:
  >
  > add the following helper - either in stmmac, or more generically
  > (phylib? - in which case its name will need changing.)
  >
  > static long stmmac_get_rgmii_clock(int speed)
  > {
  >        switch (speed) {
  >        case SPEED_10:
  >                return 2500000;
  >
  >        case SPEED_100:
  >                return 25000000;
  >
  >        case SPEED_1000:
  >                return 125000000;
  >
  >        default:
  >                return -ENVAL;
  >        }
  > }
  >
  > Then, this can become:
  >
  >        long tx_clk_rate;
  >
  >        ...
  >
  >        tx_clk_rate = stmmac_get_rgmii_clock(speed);
  >        if (tx_clk_rate < 0) {
  >                dev_err(gmac->dev, "Unsupported/Invalid speed: %d\n", speed);
  >                return;
  >        }
  >
  >        ret = clk_set_rate(gmac->tx_clk, tx_clk_rate);

Suggested-by: Russell King (Oracle) <rmk+kernel@armlinux.org.uk>
Signed-off-by: Jan Petrous (OSS) <jan.petrous@oss.nxp.com>
---
 include/linux/phy.h | 21 +++++++++++++++++++++
 1 file changed, 21 insertions(+)

diff --git a/include/linux/phy.h b/include/linux/phy.h
index a98bc91a0cde..7f6d9e7533ce 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -298,6 +298,27 @@ static inline const char *phy_modes(phy_interface_t interface)
 	}
 }
 
+/**
+ * rgmii_clock - map link speed to the clock rate
+ * @speed: link speed value
+ *
+ * Description: maps RGMII supported link speeds
+ * into the clock rates.
+ */
+static inline long rgmii_clock(int speed)
+{
+	switch (speed) {
+	case SPEED_10:
+		return 2500000;
+	case SPEED_100:
+		return 25000000;
+	case SPEED_1000:
+		return 125000000;
+	default:
+		return -EINVAL;
+	}
+}
+
 #define PHY_INIT_TIMEOUT	100000
 #define PHY_FORCE_TIMEOUT	10
 

-- 
2.46.0

