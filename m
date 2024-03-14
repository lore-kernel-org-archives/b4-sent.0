From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Date: Thu, 14 Mar 2024 12:28:35 +0300
Subject: [PATCH net v2] net: dsa: mt7530: prevent possible incorrect XTAL
 frequency selection
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240314-for-netnext-mt7530-better-fix-xtal-frequency-v2-1-fe30795593df@arinc9.com>
X-B4-Tracking: v=1; b=H4sIAELD8mUC/5WOSw7CIBRFt9K8sc/wERscuQ/TAdKHJbGggE2bp
 nuXNG7A4f3knrtCpuQpw6VZIdHks4+hCnFowA4mPAh9XzUIJk5McoEuJgxUAs0Fx9IqyfBOpVB
 C52eci3miS/T+ULALSk5np7SWvHVQJ1+JamvH3aCuQFfNwecS07JfmPge/WjyP9rEkaMyivVOa
 6e4uZrkg9VHG0fotm37An9I9ZHuAAAA
To: Daniel Golle <daniel@makrotopia.org>, DENG Qingfang <dqfext@gmail.com>, 
 Sean Wang <sean.wang@mediatek.com>, Andrew Lunn <andrew@lunn.ch>, 
 Florian Fainelli <f.fainelli@gmail.com>, 
 Vladimir Oltean <olteanv@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, 
 Landen Chao <Landen.Chao@mediatek.com>
Cc: Bartel Eerdekens <bartel.eerdekens@constell8.be>, 
 mithat.guner@xeront.com, erkin.bozoglu@xeront.com, netdev@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-mediatek@lists.infradead.org, 
 Justin Swartz <justin.swartz@risingedge.co.za>, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710408527; l=6807;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=b3iyIQB+IfaOXBCFV+CLb00V/DTdBVGoIX1+WquqbvY=;
 b=Ipl+/Xf00qHI5kU6sQQr2t9e/tXIrxQha0M6Rg9B5s1AJvw/WD/0qGsj5wKPMdj2NU+7fw4JW
 AwKYa8g+h8iAgA13wPCzDbrlFJrd5GsCTjjA+VX97fIzFSXvtQe+9Kn
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On MT7530, the HT_XTAL_FSEL field of the HWTRAP register stores a 2-bit
value that represents the frequency of the crystal oscillator connected to
the switch IC. The field is populated by the state of the ESW_P4_LED_0 and
ESW_P4_LED_0 pins, which is done right after reset is deasserted.

  ESW_P4_LED_0    ESW_P3_LED_0    Frequency
  -----------------------------------------
  0               0               Reserved
  0               1               20MHz
  1               0               40MHz
  1               1               25MHz

On MT7531, the XTAL25 bit of the STRAP register stores this. The LAN0LED0
pin is used to populate the bit. 25MHz when the pin is high, 40MHz when
it's low.

These pins are also used with LEDs, therefore, their state can be set to
something other than the bootstrapping configuration. For example, a link
may be established on port 3 before the DSA subdriver takes control of the
switch which would set ESW_P3_LED_0 to high.

Currently on mt7530_setup() and mt7531_setup(), 1000 - 1100 usec delay is
described between reset assertion and deassertion. Some switch ICs in real
life conditions cannot always have these pins set back to the bootstrapping
configuration before reset deassertion in this amount of delay. This causes
wrong crystal frequency to be selected which puts the switch in a
nonfunctional state after reset deassertion.

The tests below are conducted on an MT7530 with a 40MHz crystal oscillator
by Justin Swartz.

With a cable from an active peer connected to port 3 before reset, an
incorrect crystal frequency (0b11 = 25MHz) is selected:

                      [1]                  [3]     [5]
                      :                    :       :
              _____________________________         __________________
ESW_P4_LED_0                               |_______|
              _____________________________
ESW_P3_LED_0                               |__________________________

                       :                  : :     :
                       :                  : [4]...:
                       :                  :
                       [2]................:

[1] Reset is asserted.
[2] Period of 1000 - 1100 usec.
[3] Reset is deasserted.
[4] Period of 315 usec. HWTRAP register is populated with incorrect
    XTAL frequency.
[5] Signals reflect the bootstrapped configuration.

Increase the delay between reset_control_assert() and
reset_control_deassert(), and gpiod_set_value_cansleep(priv->reset, 0) and
gpiod_set_value_cansleep(priv->reset, 1) to 5000 - 5100 usec. This amount
ensures a higher possibility that the switch IC will have these pins back
to the bootstrapping configuration before reset deassertion.

With a cable from an active peer connected to port 3 before reset, the
correct crystal frequency (0b10 = 40MHz) is selected:

                      [1]        [2-1]     [3]     [5]
                      :          :         :       :
              _____________________________         __________________
ESW_P4_LED_0                               |_______|
              ___________________           _______
ESW_P3_LED_0                     |_________|       |__________________

                       :          :       : :     :
                       :          [2-2]...: [4]...:
                       [2]................:

[1] Reset is asserted.
[2] Period of 5000 - 5100 usec.
[2-1] ESW_P3_LED_0 goes low.
[2-2] Remaining period of 5000 - 5100 usec.
[3] Reset is deasserted.
[4] Period of 310 usec. HWTRAP register is populated with bootstrapped
    XTAL frequency.
[5] Signals reflect the bootstrapped configuration.

ESW_P3_LED_0 low period before reset deassertion:

              5000 usec
            - 5100 usec
    TEST     RESET HOLD
       #         (usec)
  ---------------------
       1           5410
       2           5440
       3           4375
       4           5490
       5           5475
       6           4335
       7           4370
       8           5435
       9           4205
      10           4335
      11           3750
      12           3170
      13           4395
      14           4375
      15           3515
      16           4335
      17           4220
      18           4175
      19           4175
      20           4350

     Min           3170
     Max           5490

  Median       4342.500
     Avg       4466.500

Revert commit 2920dd92b980 ("net: dsa: mt7530: disable LEDs before reset").
Changing the state of pins via reset assertion is simpler and more
efficient than doing so by setting the LED controller off.

Fixes: b8f126a8d543 ("net-next: dsa: add dsa support for Mediatek MT7530 switch")
Fixes: c288575f7810 ("net: dsa: mt7530: Add the support of MT7531 switch")
Co-developed-by: Justin Swartz <justin.swartz@risingedge.co.za>
Signed-off-by: Justin Swartz <justin.swartz@risingedge.co.za>
Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Changes in v2:
- Feature Justin as a co-author.
- Link to v1: https://lore.kernel.org/r/20240313-for-netnext-mt7530-better-fix-xtal-frequency-v1-1-5a50df99f51a@arinc9.com
---
 drivers/net/dsa/mt7530.c | 14 ++++----------
 1 file changed, 4 insertions(+), 10 deletions(-)

diff --git a/drivers/net/dsa/mt7530.c b/drivers/net/dsa/mt7530.c
index 678b51f9cea6..6986f538a4d0 100644
--- a/drivers/net/dsa/mt7530.c
+++ b/drivers/net/dsa/mt7530.c
@@ -2192,22 +2192,16 @@ mt7530_setup(struct dsa_switch *ds)
 		}
 	}
 
-	/* Disable LEDs before reset to prevent the MT7530 sampling a
-	 * potentially incorrect HT_XTAL_FSEL value.
-	 */
-	mt7530_write(priv, MT7530_LED_EN, 0);
-	usleep_range(1000, 1100);
-
 	/* Reset whole chip through gpio pin or memory-mapped registers for
 	 * different type of hardware
 	 */
 	if (priv->mcm) {
 		reset_control_assert(priv->rstc);
-		usleep_range(1000, 1100);
+		usleep_range(5000, 5100);
 		reset_control_deassert(priv->rstc);
 	} else {
 		gpiod_set_value_cansleep(priv->reset, 0);
-		usleep_range(1000, 1100);
+		usleep_range(5000, 5100);
 		gpiod_set_value_cansleep(priv->reset, 1);
 	}
 
@@ -2420,11 +2414,11 @@ mt7531_setup(struct dsa_switch *ds)
 	 */
 	if (priv->mcm) {
 		reset_control_assert(priv->rstc);
-		usleep_range(1000, 1100);
+		usleep_range(5000, 5100);
 		reset_control_deassert(priv->rstc);
 	} else {
 		gpiod_set_value_cansleep(priv->reset, 0);
-		usleep_range(1000, 1100);
+		usleep_range(5000, 5100);
 		gpiod_set_value_cansleep(priv->reset, 1);
 	}
 

---
base-commit: d7d75124965aee23e5e4421d78376545cf070b0a
change-id: 20240312-for-netnext-mt7530-better-fix-xtal-frequency-31e6f599317f

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

