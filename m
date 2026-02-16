From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Date: Mon, 16 Feb 2026 18:11:09 +0100
Subject: [PATCH] net: phy: realtek: Add support for PHY LEDs on RTL8211F-VD
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260216-rtl8211fvd-add-leds-v1-1-a2b8617bbf80@gmail.com>
X-B4-Tracking: v=1; b=H4sIAKxPk2kC/x3MzQpAUBBA4VfRrE2ZKePnVWQhM5gSuldS8u5ul
 t/inAeiBbcIbfZAsMuj71sC5RmMy7DNhq7JwAVLwSQYzrVmoulSHFRxNY1YsZUqItYwQSqPYJP
 f/7Xr3/cDklKhhGUAAAA=
X-Change-ID: 20260216-rtl8211fvd-add-leds-72e5d666e921
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: Miroslav Ondra <ondra@faster.cz>, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771261999; l=1456;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=UcDBB6aqn6VGJO+wrWmfuuDhMbNI+KYuwnnokfwejMY=;
 b=q1iiWNCuapGkYpnUzMCoonZHxYfGwV7ZC8l5ct9AzwknkjTQeTtkfca2avgxpzrlskW2I1AJX
 nCj+z1JNK7pDiX4V65P3N8Mj6sOv/RxpPodcdDwYM/UoPRdy5n6coGV
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Realtek RTL8211F-VD has the same LED configuration
and registers as RTL8211F.
Use the existing LED related functions for this chip,
so it is possible to also use the netdev trigger.

Tested on ROCK Pi E.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
I have been trying to match LED behavior of RTL8211F-VD with RTL8211E
and found out the RTL8211F is supported already,
which by the look in datasheet matched the RTL8211F-VD.
So I have reused the functions and tested on ROCK Pi E.
---
 drivers/net/phy/realtek/realtek_main.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/net/phy/realtek/realtek_main.c b/drivers/net/phy/realtek/realtek_main.c
index 75565fbdbf6d..530b4e26d16e 100644
--- a/drivers/net/phy/realtek/realtek_main.c
+++ b/drivers/net/phy/realtek/realtek_main.c
@@ -2243,6 +2243,9 @@ static struct phy_driver realtek_drvs[] = {
 		.read_page	= rtl821x_read_page,
 		.write_page	= rtl821x_write_page,
 		.flags		= PHY_ALWAYS_CALL_SUSPEND,
+		.led_hw_is_supported = rtl8211x_led_hw_is_supported,
+		.led_hw_control_get = rtl8211f_led_hw_control_get,
+		.led_hw_control_set = rtl8211f_led_hw_control_set,
 	}, {
 		.name		= "Generic FE-GE Realtek PHY",
 		.match_phy_device = rtlgen_match_phy_device,

---
base-commit: 350adaf7fde9fdbd9aeed6d442a9ae90c6a3ab97
change-id: 20260216-rtl8211fvd-add-leds-72e5d666e921

Best regards,
-- 
Kryštof Černý <cleverline1mc@gmail.com>

