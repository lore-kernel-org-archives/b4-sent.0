From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 05 Jun 2026 22:42:43 -0700
Subject: [PATCH net-next v4 12/16] net: phy: ncn26000: Support for loopback
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260605-s2500-mac-phy-support-v4-12-de0fbc13c6d8@onsemi.com>
References: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
In-Reply-To: <20260605-s2500-mac-phy-support-v4-0-de0fbc13c6d8@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, 
 Piergiorgio Beruto <pier.beruto@onsemi.com>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1780724562; l=886;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=6j9FApr9mdiEL4bEIZDwlR2AIaPGGvliDOcnuk/FhSQ=;
 b=rtNvJ5PfVSv8jTsb9GV2cu+Qtb2mF1ILOlEL2pfqnbKdFaLAM5m+RqUSMgxp+/Aqt5siWIYbN
 ZYWQn6EqCfCDxYxKiuYpyxiVJIkoLaG2mpwpZJbXu3DHRhpEFx8L+y4
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Adding loopback support for S2500 internal PHY to help running
loopback test through ethtool

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
---
 drivers/net/phy/ncn26000.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/phy/ncn26000.c b/drivers/net/phy/ncn26000.c
index c3a34b2c524d..afafa81dc22b 100644
--- a/drivers/net/phy/ncn26000.c
+++ b/drivers/net/phy/ncn26000.c
@@ -178,6 +178,7 @@ static struct phy_driver ncn26000_driver[] = {
 		.config_aneg           = ncn26000_config_aneg,
 		.read_status           = ncn26000_read_status,
 		.handle_interrupt      = ncn26000_handle_interrupt,
+		.set_loopback          = genphy_loopback_fixed_speed,
 		.set_plca_cfg          = ncn26000_c45_plca_set_cfg,
 		.get_plca_cfg          = genphy_c45_plca_get_cfg,
 		.get_plca_status       = genphy_c45_plca_get_status,

-- 
2.43.0

