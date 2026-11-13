From: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>
Date: Fri, 13 Nov 2026 08:59:24 -0800
Subject: [PATCH net-next v11 05/14] net: ethernet: microchip: lan865x:
 Depends on PTP_1588_CLOCK_OPTIONAL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-s2500-mac-phy-support-v11-5-7a186141952c@onsemi.com>
References: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
In-Reply-To: <20261113-s2500-mac-phy-support-v11-0-7a186141952c@onsemi.com>
To: Selva Rajagopal <selvamani.rajagopal@onsemi.com>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Parthiban Veerasooran <parthiban.veerasooran@microchip.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, 
 Randy Dunlap <rdunlap@infradead.org>, 
 Richard Cochran <richardcochran@gmail.com>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, Eric Dumazet <edumazet@kernel.org>, 
 Piergiorgio Beruto <piergiorgio.beruto@gmail.com>, 
 Eric Dumazet <edumazet@kernel.org>
Cc: Selva Rajagopal <Selvamani.Rajagopal@onsemi.com>, 
 netdev@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-doc@vger.kernel.org, 
 Jerry Ray <jerry.ray@microchip.com>, 
 Ciprian Regus <ciprian.regus@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794589162; l=995;
 i=Selvamani.Rajagopal@onsemi.com; s=20260531; h=from:subject:message-id;
 bh=Wj4qNO+pltej/S7LvUHDWa6nEFAP4MrIYcLCWkuKPJc=;
 b=vJ2gca9H5Wtp6WO/1h7EIJ3ofko42ULtcL9bO0LF0GsD4vmRIvI6czmjmEBLzK7vKyCBER/EB
 zIojPN+nAFsBgNjCdvzI4v3O7pOy1S6NkBPl38MsZVSauHYZXIo7X3V
X-Developer-Key: i=Selvamani.Rajagopal@onsemi.com; a=ed25519;
 pk=5QRdM0HS/LGWWcUZZ9hVfZ+qbPQGZCumcTXOiN7Fyug=
X-Endpoint-Received: by B4 Relay for Selvamani.Rajagopal@onsemi.com/20260531 with auth_id=803
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PTP_1588_CLOCK_OPTIONAL dependency to LAN865X. A following
patch makes OA_TC6 depend on it, but "select" ignores that, so
LAN865X built in with PTP_1588_CLOCK=m would link-fail on
ptp_clock_register().

Signed-off-by: Selvamani Rajagopal <Selvamani.Rajagopal@onsemi.com>

---
changes in v11
  - Moved the vendor changes into its own patch.
  - New patch in v11.
---
 drivers/net/ethernet/microchip/lan865x/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/microchip/lan865x/Kconfig b/drivers/net/ethernet/microchip/lan865x/Kconfig
index 7f2a4e7e1915..342172cb8837 100644
--- a/drivers/net/ethernet/microchip/lan865x/Kconfig
+++ b/drivers/net/ethernet/microchip/lan865x/Kconfig
@@ -8,6 +8,7 @@ if NET_VENDOR_MICROCHIP
 config LAN865X
 	tristate "LAN865x support"
 	depends on SPI
+	depends on PTP_1588_CLOCK_OPTIONAL
 	select OA_TC6
 	help
 	  Support for the Microchip LAN8650/1 Rev.B0/B1 MACPHY Ethernet chip. It

-- 
2.43.0

