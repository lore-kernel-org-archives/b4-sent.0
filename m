From: Hleb Shauchenka <me@marleb.org>
Date: Sat, 07 Nov 2026 18:00:47 +0100
Subject: [PATCH net-next v2 3/3] net: phy: realtek: register hwmon thermal
 zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261107-realtek-hwmon-tz-v2-3-6b9a69d44470@marleb.org>
References: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
In-Reply-To: <20261107-realtek-hwmon-tz-v2-0-6b9a69d44470@marleb.org>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Florian Fainelli <f.fainelli@gmail.com>
Cc: netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Hleb Shauchenka <me@marleb.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1760; i=me@marleb.org;
 h=from:subject:message-id; bh=HRvjZ9m/qJc8A0xrX1vhVTFReKgYes98W1JLF6cq46k=;
 b=owJ4nJvAy8zAJTZJnM368y8lXsbTakkMWe8jU538Op75bptzvW/PuZbUDslkk1MZT10m+wWbv
 +oNCt/8O7mjlIVBjItBVkyRZVNzkejTldFvXav3ZMHMYWUCGcLAxSkAE4ktZGQ4YS7769WX958N
 lsysmHBHONXXc2Zpo2XBxQP+dt6+CxS3MfyPbzmwPfLPm/70lh/T7hz+9npqo6hhxowLMu03Yiq
 zVQOZAE5xS/4=
X-Developer-Key: i=me@marleb.org; a=openpgp;
 fpr=B2837215E5A95BED457BBC6A9217063BF3FA220D
X-Endpoint-Received: by B4 Relay for me@marleb.org/default with auth_id=1394
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Realtek PHY hwmon device exposes the PHY temperature, but its
channel info lacks HWMON_C_REGISTER_TZ, so the hwmon core does not
register the sensor with the thermal framework and device-tree
thermal zones that reference the PHY cannot bind.

Set the flag, as the Aquantia PHY driver does. In mainline this
affects the PHYs whose hwmon device rtl822x_probe() registers, the
RTL8221B-VB-CG, RTL8221B-VM-CG and RTL8251B, when the device tree
describes them. The internal NBASE-T PHYs normally have no device
tree node, so the hwmon core registers no thermal zone for them.

I tested this on a Zyxel XGS1250-12 B1 with OpenWrt's Linux 6.18.55,
where OpenWrt's out-of-tree RTL8261N support calls
rtl822x_hwmon_init(): the three PHY thermal zones register, and an
emulated 85 C reading on one of them (CONFIG_THERMAL_EMULATION)
switches the fan on through an 80 C trip and off again once cleared.

This patch was prepared with AI assistance (Claude Opus 5.5 and Sol
6.1), which also helped investigate the problem and run the tests on
my switch.

Reviewed-by: Andrew Lunn <andrew@lunn.ch>
Signed-off-by: Hleb Shauchenka <me@marleb.org>
---
 drivers/net/phy/realtek/realtek_hwmon.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/phy/realtek/realtek_hwmon.c b/drivers/net/phy/realtek/realtek_hwmon.c
index b6b2806e2..021064edd 100644
--- a/drivers/net/phy/realtek/realtek_hwmon.c
+++ b/drivers/net/phy/realtek/realtek_hwmon.c
@@ -55,6 +55,7 @@ static const struct hwmon_ops rtl822x_hwmon_ops = {
 };
 
 static const struct hwmon_channel_info * const rtl822x_hwmon_info[] = {
+	HWMON_CHANNEL_INFO(chip, HWMON_C_REGISTER_TZ),
 	HWMON_CHANNEL_INFO(temp, HWMON_T_INPUT | HWMON_T_MAX),
 	NULL
 };

-- 
2.56.0

