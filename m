From: Franck BAUR <franck.baur.67@gmail.com>
Date: Sun, 11 Oct 2026 14:33:21 +0200
Subject: [PATCH net] net: jme: keep RX MAC clock enabled for WoL
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261011-jme-wol-submit-v1-1-9cc033e259e4@gmail.com>
X-B4-Tracking: v=1; b=H4sIABCCy2oC/x3MTQ5AMBBA4avIrE2iBKmriAU1GNFWWn+J9O4ay
 2/x3gueHJOHJnnB0cWerYkQaQJq6c1MyGM05FleiUwIXDXhbTf056D5QDlOsldKlUVVQ4x2RxM
 //7AFQwd0IXyO2YvEZQAAAA==
X-Change-ID: 20261011-jme-wol-submit-9df9accc5367
To: Guo-Fu Tseng <cooldavid@cooldavid.org>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@kernel.org>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Franck BAUR <franck.baur.67@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791722003; l=1689;
 i=franck.baur.67@gmail.com; s=20261011; h=from:subject:message-id;
 bh=SeoQOmO2eEg732RNb6ToQJ2L/+DWTL9snNuAeoOV8m4=;
 b=pUZUqe8RJr9IE7ULUKkLVKCCfLZTMEaEsk0YYDHmCA8Fzm9XmN5OcL/qYwDdNWm8jaxFAyDbS
 yR8OCoroeaOCDBNQIvLd/wV2NpEZgojCkgOcr5qfAvAJI+VfGf1nOAc
X-Developer-Key: i=franck.baur.67@gmail.com; a=ed25519;
 pk=4AAmINL6MxJGFmb3HM2Vp734BIHvnGs3+aOTK/FcJ0Y=
X-Endpoint-Received: by B4 Relay for franck.baur.67@gmail.com/20261011 with auth_id=1158
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The suspend path disables the RX engine and resets the MAC before
jme_powersave_phy() programs PMCS for wake-on-LAN. The MAC reset leaves
GPREG1_RXCLKOFF set, so the RX MAC clock remains gated when WoL is
armed.

On a JMicron JMC250 [197b:0250] revision 03, PMCS_MFEN is programmed
correctly but Magic Packet detection does not work while the RX MAC
clock is gated. Instrumenting JME_PMCS showed that MFDET remained clear
after receiving Magic Packets.

Re-enabling the RX MAC clock immediately before enabling WoL makes
MFDET assert and restores wake from ACPI S3. An A/B test without a
Magic Packet remained suspended until the RTC wake alarm. The wakeup
was reproduced repeatedly with the patched driver.

Keep the RX MAC clock running while WoL is armed.

Fixes: 854a2e7c331a ("jme: Safer MAC processor reset sequence")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: Franck BAUR <franck.baur.67@gmail.com>
---
 drivers/net/ethernet/jme.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/net/ethernet/jme.c b/drivers/net/ethernet/jme.c
index 25ec5f757c6828a5f5241340bf3fb01d8e0aa3e9..27ac7405f76fed169d9f1fa84d9875611dcf119c 100644
--- a/drivers/net/ethernet/jme.c
+++ b/drivers/net/ethernet/jme.c
@@ -1892,6 +1892,7 @@ jme_powersave_phy(struct jme_adapter *jme)
 		jme_set_100m_half(jme);
 		if (jme->reg_pmcs & (PMCS_LFEN | PMCS_LREN))
 			jme_wait_link(jme);
+		jme_mac_rxclk_on(jme);
 		jme_clear_pm_enable_wol(jme);
 	} else {
 		jme_phy_off(jme);

---
base-commit: af32da41b0327b9c6a37856ba82b6760d6c8d10e
change-id: 20261011-jme-wol-submit-9df9accc5367

Best regards,
-- 
Franck BAUR <franck.baur.67@gmail.com>

