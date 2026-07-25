From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Sat, 25 Jul 2026 10:59:17 +0200
Subject: [PATCH 5/6] PCI/pwrctrl: tc9563: Rename DSP3 to VDSP
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260725-tc9563-fix-v1-5-ec4286e31331@oss.qualcomm.com>
References: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
In-Reply-To: <20260725-tc9563-fix-v1-0-ec4286e31331@oss.qualcomm.com>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 Lorenzo Pieralisi <lpieralisi@kernel.org>, 
 =?utf-8?q?Krzysztof_Wilczy=C5=84ski?= <kwilczynski@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krishna Chaitanya Chundru <krishna.chundru@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>
Cc: linux-pci@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Alex Elder <elder@riscstar.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1939;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=ESW4WZ2Gmyx1Q1J/bfntG851pFg9myw00QxfynrufIc=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqZHr8txpz9yA/RvyAhKnC8f78s7QZAAQC6FBiK
 zJg8MLnkJqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCamR6/AAKCRBVnxHm/pHO
 9Si2CACbnfK3zT6X0gL1KX8QxvgnvEbH5Lo0d6o+o3sikAXDbZFueZ5H5IgmRJJ2giTrXZf2WOZ
 bG4Uf15QB+relNpiK0fDM2x85dOWAp0x06LrEPeI/316UdiEqJB3rG8n8q/P+iGzCnf99lPx6aX
 cKXEg3K0beVzj9skJRv/8PlS7rJUxI+f1hFUQOmnb3YEUjOZMe6hRW0M1qyvudqa98gzLPqKb8k
 wzRFXSz0yHiP17IIx/7SNASnSP9etUmGzJ9IpUKvF830NiV2iRr48VGgMXxZkq7akPA1EboBlZy
 iPQHb9uX5BPvuud4fUUwmfwVZoi4lUTq9UUAy8mMod0pYbv/
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

TC9563 Reference Manual calls DSP3 as VDSP (Virtual Downstream Port). Hence
name it as such to avoid ambiguity.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c | 14 +++++++-------
 1 file changed, 7 insertions(+), 7 deletions(-)

diff --git a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
index 28e9ec3e172a..f1179737f221 100644
--- a/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
+++ b/drivers/pci/pwrctrl/pci-pwrctrl-tc9563.c
@@ -80,7 +80,7 @@ enum tc9563_pwrctrl_ports {
 	TC9563_USP,
 	TC9563_DSP1,
 	TC9563_DSP2,
-	TC9563_DSP3,
+	TC9563_VDSP,
 	TC9563_ETHERNET,
 	TC9563_MAX
 };
@@ -328,8 +328,8 @@ static int tc9563_pwrctrl_set_tx_amplitude(struct tc9563_pwrctrl *tc9563,
 	case TC9563_DSP2:
 		port_access = 0x8;
 		break;
-	case TC9563_DSP3:
-		dev_dbg(dev, "Tx amplitude tuning not supported for DSP3\n");
+	case TC9563_VDSP:
+		dev_dbg(dev, "Tx amplitude tuning not supported for VDSP\n");
 		return 0;
 	default:
 		return -EINVAL;
@@ -368,8 +368,8 @@ static int tc9563_pwrctrl_disable_dfe(struct tc9563_pwrctrl *tc9563,
 		port_access = 0x8;
 		lane_access = 0x1;
 		break;
-	case TC9563_DSP3:
-		dev_dbg(dev, "DFE tuning not supported for DSP3\n");
+	case TC9563_VDSP:
+		dev_dbg(dev, "DFE tuning not supported for VDSP\n");
 		return 0;
 	default:
 		return -EINVAL;
@@ -612,10 +612,10 @@ static int tc9563_pwrctrl_probe(struct platform_device *pdev)
 			break;
 
 		/*
-		 * The integrated Ethernet MAC Endpoint under DSP3 is a single
+		 * The integrated Ethernet MAC Endpoint under VDSP is a single
 		 * device whose functions share the same config registers.
 		 */
-		if (port == TC9563_DSP3) {
+		if (port == TC9563_VDSP) {
 			struct device_node *eth __free(device_node) =
 					of_get_next_available_child(child, NULL);
 			if (eth) {

-- 
2.43.0

