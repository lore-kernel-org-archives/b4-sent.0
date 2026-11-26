From: Athira Palliprath <palliprath@chromium.org>
Date: Thu, 26 Nov 2026 09:04:21 +0000
Subject: [PATCH] mmc: sdhci-pci-gli: GL9763E: Fix LPM ordering and restore
 hw settings on resume
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-gl9763e-lpm-ordering-v1-1-71ce1b4edb89@chromium.org>
X-B4-Tracking: v=1; b=H4sIABT2B2sC/x3MQQqAIBBA0avErBtII8uuEi1CRxswC4UIpLsnL
 f/i/QKZElOGuSmQ6ObMZ6wh2gbMvkVPyLY2yE4qIaRCH/SoesJwHXgmW3X0aOwwaKHdZIyESq9
 Ejp9/u6zv+wFV+96GZgAAAA==
X-Change-ID: 20261126-gl9763e-lpm-ordering-cd55919f8cc2
To: Adrian Hunter <adrian.hunter@intel.com>, Ulf Hansson <ulfh@kernel.org>
Cc: linux-mmc@vger.kernel.org, 
 Victor Shih <victor.shih@genesyslogic.com.tw>, 
 Ben Chuang <ben.chuang@genesyslogic.com.tw>, 
 Sven van Ashbrook <svenva@chromium.org>, Tomasz Figa <tfiga@chromium.org>, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Athira Palliprath <palliprath@chromium.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795683862; l=5060;
 i=palliprath@chromium.org; h=from:subject:message-id;
 bh=ilN74LfM2q1x899iqprsDyA2jTJ6XG0MVTIisRfUF2o=;
 b=cyUkBRGqlhmcZaJl25I++lyHNnWQ1raS16OoKk+eV5P9gwX9m8f3RMX+nob4XCWVyXRDIpWeE
 MvnBje/PHiWBNIEKbmc8TzPeqfLSEm4UZ1lHE8J11hgj20CP80nLDGe
X-Developer-Key: i=palliprath@chromium.org; a=ed25519;
 pk=tumKET4w5oWCmHTf0TugEzwRThbeZ+jP/wMfBOM/w9U=
X-Endpoint-Received: by B4 Relay for palliprath@chromium.org/default with auth_id=1651
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In gl9763e_runtime_suspend() and gl9763e_suspend(), LPM negotiation is
currently enabled before SDHCI/CQHCI MMIO register accesses finish, and
in gl9763e_runtime_resume() and gl9763e_resume(), SDHCI/CQHCI MMIO
registers are accessed before LPM negotiation is disabled. Because the
GL9763E has known hardware ASPM/L1 exit and replay-timer issues when
accessed while L1 negotiation is enabled, this ordering allows the
controller to enter L1 mid-transition and become inaccessible (0xffffffff
MMIO reads).

In addition, gl9763e_hw_setting() (which programs AXI_REQ, L1DLY,
HS400_RXDLY, and masks the AER replay timer timeout) is only executed
during probe and is not restored after D3cold or a controller reset.

Fix the ordering so LPM negotiation is disabled (and gl9763e_hw_setting()
is re-applied) before touching SDHCI/CQHCI MMIO on resume, and LPM
negotiation is re-enabled only after MMIO accesses complete on suspend.

Fixes: f9e5b33934ce ("mmc: host: Improve I/O read/write performance for GL9763E")
Fixes: 1202d617e3d0 ("mmc: sdhci-pci-gli: fix LPM negotiation so x86/S0ix SoCs can suspend")
Fixes: 340be332e420 ("mmc: sdhci-pci-gli: GL9763e: Mask the replay timer timeout of AER")
Cc: stable@vger.kernel.org
Signed-off-by: Athira Palliprath <palliprath@chromium.org>
---
 drivers/mmc/host/sdhci-pci-gli.c | 56 ++++++++++++++++++++--------------------
 1 file changed, 28 insertions(+), 28 deletions(-)

diff --git a/drivers/mmc/host/sdhci-pci-gli.c b/drivers/mmc/host/sdhci-pci-gli.c
index 66452ed8c..da3ee8b90 100644
--- a/drivers/mmc/host/sdhci-pci-gli.c
+++ b/drivers/mmc/host/sdhci-pci-gli.c
@@ -1880,13 +1880,13 @@ static int gl9763e_runtime_suspend(struct sdhci_pci_chip *chip)
 	struct sdhci_host *host = slot->host;
 	u16 clock;
 
-	/* Enable LPM negotiation to allow entering L1 state */
-	gl9763e_set_low_power_negotiation(slot, true);
-
 	clock = sdhci_readw(host, SDHCI_CLOCK_CONTROL);
 	clock &= ~(SDHCI_CLOCK_PLL_EN | SDHCI_CLOCK_CARD_EN);
 	sdhci_writew(host, clock, SDHCI_CLOCK_CONTROL);
 
+	/* Enable LPM negotiation only after SDHCI MMIO accesses complete. */
+	gl9763e_set_low_power_negotiation(slot, true);
+
 	return 0;
 }
 
@@ -1896,6 +1896,13 @@ static int gl9763e_runtime_resume(struct sdhci_pci_chip *chip)
 	struct sdhci_host *host = slot->host;
 	u16 clock;
 
+	/*
+	 * Restore vendor PCI settings (lost across D3cold/reset) and disable
+	 * LPM negotiation before touching SDHCI MMIO registers.
+	 */
+	gl9763e_hw_setting(slot);
+	gl9763e_set_low_power_negotiation(slot, false);
+
 	if (host->mmc->ios.power_mode != MMC_POWER_ON)
 		return 0;
 
@@ -1916,9 +1923,6 @@ static int gl9763e_runtime_resume(struct sdhci_pci_chip *chip)
 	clock |= SDHCI_CLOCK_CARD_EN;
 	sdhci_writew(host, clock, SDHCI_CLOCK_CONTROL);
 
-	/* Disable LPM negotiation to avoid entering L1 state. */
-	gl9763e_set_low_power_negotiation(slot, false);
-
 	return 0;
 }
 #endif
@@ -1939,21 +1943,19 @@ static int gl9763e_resume(struct sdhci_pci_chip *chip)
 	struct sdhci_pci_slot *slot = chip->slots[0];
 	int ret;
 
-	ret = sdhci_pci_gli_resume(chip);
-	if (ret)
-		return ret;
-
-	ret = cqhci_resume(slot->host->mmc);
-	if (ret)
-		return ret;
-
 	/*
-	 * Disable LPM negotiation to bring device back in sync
-	 * with its runtime_pm state.
+	 * Restore vendor PCI config settings (AXI_REQ, L1DLY, HS400_RXDLY,
+	 * AER replay-timer-timeout mask) lost across D3cold/reset and disable
+	 * LPM negotiation before touching SDHCI/CQHCI MMIO registers.
 	 */
+	gl9763e_hw_setting(slot);
 	gl9763e_set_low_power_negotiation(slot, false);
 
-	return 0;
+	ret = sdhci_pci_gli_resume(chip);
+	if (ret)
+		return ret;
+
+	return cqhci_resume(slot->host->mmc);
 }
 
 static int gl9763e_suspend(struct sdhci_pci_chip *chip)
@@ -1961,28 +1963,26 @@ static int gl9763e_suspend(struct sdhci_pci_chip *chip)
 	struct sdhci_pci_slot *slot = chip->slots[0];
 	int ret;
 
-	/*
-	 * Certain SoCs can suspend only with the bus in low-
-	 * power state, notably x86 SoCs when using S0ix.
-	 * Re-enable LPM negotiation to allow entering L1 state
-	 * and entering system suspend.
-	 */
-	gl9763e_set_low_power_negotiation(slot, true);
-
 	ret = cqhci_suspend(slot->host->mmc);
 	if (ret)
-		goto err_suspend;
+		return ret;
 
 	ret = sdhci_suspend_host(slot->host);
 	if (ret)
 		goto err_suspend_host;
 
+	/*
+	 * Certain SoCs can suspend only with the bus in low-
+	 * power state, notably x86 SoCs when using S0ix.
+	 * Re-enable LPM negotiation to allow entering L1 state
+	 * only after CQHCI/SDHCI MMIO suspend accesses finish.
+	 */
+	gl9763e_set_low_power_negotiation(slot, true);
+
 	return 0;
 
 err_suspend_host:
 	cqhci_resume(slot->host->mmc);
-err_suspend:
-	gl9763e_set_low_power_negotiation(slot, false);
 	return ret;
 }
 #endif

---
base-commit: d2616724e01132376c78872b8324f38659af9f28
change-id: 20261126-gl9763e-lpm-ordering-cd55919f8cc2

Best regards,
-- 
Athira Palliprath <palliprath@chromium.org>

