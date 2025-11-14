From: Maud Spierings <maudspierings@gocontroll.com>
Date: Fri, 14 Nov 2025 12:39:32 +0100
Subject: [PATCH] net: phy: fix doc for rgii_clock()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251114-rgmii_clock-v1-1-e5c12d6cafa6@gocontroll.com>
X-B4-Tracking: v=1; b=H4sIAPMUF2kC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDQ0MT3aL03MzM+OSc/ORsXUNjC8sUAzMz86Q0cyWgjoKi1LTMCrBp0bG
 1tQDDHgxRXQAAAA==
X-Change-ID: 20251114-rgmii_clock-1389d0667bf7
To: Andrew Lunn <andrew@lunn.ch>, Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Maud Spierings <maudspierings@gocontroll.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763120376; l=1933;
 i=maudspierings@gocontroll.com; s=20250214; h=from:subject:message-id;
 bh=UQyyfUMTpe4dFX3C6T5OVzvfPF16qoNqoI0Ju4mbbZc=;
 b=diLkiXi59gVwA0zYEyEXxtzWagQqnkw7B+Hdj9ZJ3wX5GBFQdTmVFaEE5WCY6ztO+9rJPuaxD
 tyNHKdC92yqCvofN5jwszOP97mpWkqNu770RMJEoiU7oVwa+Hdynp+h
X-Developer-Key: i=maudspierings@gocontroll.com; a=ed25519;
 pk=7chUb8XpaTQDvWhzTdHC0YPMkTDloELEC7q94tOUyPg=
X-Endpoint-Received: by B4 Relay for maudspierings@gocontroll.com/20250214 with auth_id=341
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The doc states that the clock values also apply to the rmii mode,
"as the clock rates are identical". But as far as I can find the
clock rate for rmii is 50M at both 10 and 100 mbits/s [1].

Link: https://en.wikipedia.org/wiki/Media-independent_interface [1]

Signed-off-by: Maud Spierings <maudspierings@gocontroll.com>
---
This patch is also part question, I am working on an imx8mp based device
with the dwmac-imx driver. In imx_dwmac_set_clk_tx_rate() and
imx_dwmac_fix_speed() both rmii and mii are excluded from setting the
clock rate with this function.

But from what I can read only rmii should be excluded, I am not very
knowledgable with regards to networkinging stuff so my info is
coming from wikipedia.

I am adding this exclusion to the barebox bootloader, but I am not sure
if I should also be excluding mii as is being done upstream.
---
 include/linux/phy.h | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/include/linux/phy.h b/include/linux/phy.h
index bf5457341ca8..e941b280c196 100644
--- a/include/linux/phy.h
+++ b/include/linux/phy.h
@@ -296,9 +296,9 @@ static inline const char *phy_modes(phy_interface_t interface)
  * @speed: link speed value
  *
  * Description: maps RGMII supported link speeds into the clock rates.
- * This can also be used for MII, GMII, and RMII interface modes as the
- * clock rates are identical, but the caller must be aware that errors
- * for unsupported clock rates will not be signalled.
+ * This can also be used for MII and GMII interface modes as the clock rates
+ * are identical, but the caller must be aware that errors for unsupported
+ * clock rates will not be signalled.
  *
  * Returns: clock rate or negative errno
  */

---
base-commit: 0f2995693867bfb26197b117cd55624ddc57582f
change-id: 20251114-rgmii_clock-1389d0667bf7

Best regards,
-- 
Maud Spierings <maudspierings@gocontroll.com>

