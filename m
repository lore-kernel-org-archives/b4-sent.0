From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Tue, 24 Nov 2026 14:09:54 -0800
Subject: [PATCH net-next v12 06/15] net: ethernet: adi: adin1140: Depends
 on PTP_1588_CLOCK_OPTIONAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-s2500-mac-phy-support-v12-6-3575855d99f9@onsemi.com>
References: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
In-Reply-To: <20261124-s2500-mac-phy-support-v12-0-3575855d99f9@onsemi.com>
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Andrew Lunn <andrew+netdev@lunn.ch>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Richard Cochran <richardcochran@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>, Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>, 
 Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795558193; l=916;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=bUowD5pEZxYOnYYm7grV2p5YyU5Lima44YR6FQvzDY0=;
 b=Z9opoeKTrnVwXpZl+oukzs+hrs9jmWZq0DgdfrX/W4QUA2Qb12gYsvK9S1oPVbM5Z8OaofGZJ
 KrGOWPLp4VyCLc+HuTzdjgedtjyDcUikb5xEHUW82tpThyla8jism0D
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PTP_1588_CLOCK_OPTIONAL dependency to ADIN1140. A following
patch makes OA_TC6 depend on it, but "select" ignores that, so
ADIN1140 built in with PTP_1588_CLOCK=m would link-fail on
ptp_clock_register().

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v12
  - No change
changes in v11
  - Moved the vendor changes into its own patch.
  - New patch in v11.
---
 drivers/net/ethernet/adi/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/adi/Kconfig b/drivers/net/ethernet/adi/Kconfig
index bdb8ff7d15da..120a52e6b283 100644
--- a/drivers/net/ethernet/adi/Kconfig
+++ b/drivers/net/ethernet/adi/Kconfig
@@ -29,6 +29,7 @@ config ADIN1110
 config ADIN1140
 	tristate "Analog Devices ADIN1140 MAC-PHY"
 	depends on SPI
+	depends on PTP_1588_CLOCK_OPTIONAL
 	select ADIN1140_PHY
 	select OA_TC6
 	help

-- 
2.43.0

