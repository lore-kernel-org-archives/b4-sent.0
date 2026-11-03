From: Hleb Shauchenka <me@marleb.org>
Date: Tue, 03 Nov 2026 12:21:28 +0100
Subject: [PATCH net-next] net: phy: realtek: register hwmon thermal zones
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261103-realtek-hwmon-tz-v1-1-e672723c58cb@marleb.org>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMTQ7CIBBGr9LM2omFRg1exbgAnJZROzWA2tj07
 oIu3/fzFkgUmRIcmwUivTjxJAXUpgEfrAyEfCkMutV7pdoOI9l7phuG9zgJ5g+ane4O1mjlegP
 l9ojU8/xTnkAoo9Cc4fxv0tNdyedqrFtnE6GLVnyo0RR5YNmOlgXW9QvB0NILnAAAAA==
X-Change-ID: 20261103-realtek-hwmon-tz-95237a921bf9
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Hleb Shauchenka <me@marleb.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1627; i=me@marleb.org;
 h=from:subject:message-id; bh=9hvSTTecMqQziEV6E78tCmsz2y2K7B9KUH/zpfgTUOU=;
 b=owJ4nJvAy8zAJTZJnM368y8lXsbTakkMWS8PH2PdqePhNNGyaVbYOdG5i/anTGac78htv0Z2+
 rqesmXPk3g6SlkYxLgYZMUUWTY1F4k+XRn91rV6TxbMHFYmkCEMXJwCMBG9Pob/WXPzrKy3R6RV
 SszQ1U08+kljzYc9X/T2a19Nt91jcjP8OcM/m7TpLDZb3n2ffDBDNMqb0+5teo8J/3aLOqXEz9/
 9JRg5AQg5RrQ=
X-Developer-Key: i=me@marleb.org; a=openpgp;
 fpr=B2837215E5A95BED457BBC6A9217063BF3FA220D
X-Endpoint-Received: by B4 Relay for me@marleb.org/default with auth_id=1394
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Realtek PHY hwmon device exposes the PHY temperature, but its
channel info lacks HWMON_C_REGISTER_TZ, so the hwmon core does not
register the sensor with the thermal framework and device-tree
thermal zones that reference the PHY cannot bind.

Set the flag, as the Aquantia PHY driver does. This lets the RTL8261N
sensors on the Zyxel XGS1250-12 B1 drive the chassis fan through
thermal cooling maps.

Tested on a Zyxel XGS1250-12 B1 with OpenWrt's Linux 6.18.55: the
three PHY thermal zones register, and an emulated 85 C reading on one
of them (CONFIG_THERMAL_EMULATION) switches the fan on through the
existing 80 C trip and off again once cleared.

This patch was prepared with AI assistance (Claude Opus 5.5 and Sol
6.1), which also helped investigate the problem and run the tests on
my switch.

Signed-off-by: Hleb Shauchenka <me@marleb.org>
---
 drivers/net/phy/realtek/realtek_hwmon.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/phy/realtek/realtek_hwmon.c b/drivers/net/phy/realtek/realtek_hwmon.c
index ac96e2d1e..e6235df28 100644
--- a/drivers/net/phy/realtek/realtek_hwmon.c
+++ b/drivers/net/phy/realtek/realtek_hwmon.c
@@ -51,6 +51,7 @@ static const struct hwmon_ops rtl822x_hwmon_ops = {
 };
 
 static const struct hwmon_channel_info * const rtl822x_hwmon_info[] = {
+	HWMON_CHANNEL_INFO(chip, HWMON_C_REGISTER_TZ),
 	HWMON_CHANNEL_INFO(temp, HWMON_T_INPUT | HWMON_T_MAX),
 	NULL
 };

---
base-commit: 7b6ab4dbc156e2f96419715130b3d5738a306c93
change-id: 20261103-realtek-hwmon-tz-95237a921bf9

Best regards,
--  
Hleb Shauchenka <me@marleb.org>

