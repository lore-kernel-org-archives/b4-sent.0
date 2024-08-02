From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 02 Aug 2024 11:25:03 +0530
Subject: [PATCH v5 4/4] PCI: Allow PCI bridges to go to D3Hot on all
 Devicetree based platforms
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-pci-bridge-d3-v5-4-2426dd9e8e27@linaro.org>
References: <20240802-pci-bridge-d3-v5-0-2426dd9e8e27@linaro.org>
In-Reply-To: <20240802-pci-bridge-d3-v5-0-2426dd9e8e27@linaro.org>
To: Bjorn Helgaas <bhelgaas@google.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, Len Brown <lenb@kernel.org>
Cc: linux-pci@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-acpi@vger.kernel.org, lukas@wunner.de, 
 mika.westerberg@linux.intel.com, 
 Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>, 
 Hsin-Yi Wang <hsinyi@chromium.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=openpgp-sha256; l=1909;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=ysTqE45coqPvykQRZRe0VeyavgQ9+sgZKnMnxkXaMrs=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmrHTDk+wYKSA4ReZo++MT1k+y+mL9mpBeuq5iS
 rN1qLy+ebqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqx0wwAKCRBVnxHm/pHO
 9bj2B/9CHofWJVlPBG6X2dbdioyUIDnUxWxbrl1XR2oQVu+HOTwlWR1Jk7diQuhO3z4OjhGUR0w
 R9l3pknbtJ982jDRmJDsHMK3y4rQj3hHflT9zMSeF4qnzGmHEk8V06arY61nfyDQYN8scYnz+hx
 8Jf1GktYNZKDlyfF5+oRkJcn3YYLd5pawJ/G21JvXgsmyUI01CKXjpXewgKJoRpanKDt8+YkZHv
 MY41deRlZ1Crer5imiCiS8WGeEA3Hq9mVA9W4VLS1+2qpAPpM4gQ4+PV1TcqeUPQd7PH7OJoqy/
 r6+Zldu8WZQpd8iKpFFT/uIcKjLIyuq6EMKvXh0Iw0+ZKF6d
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Unlike ACPI based platforms, there are no known issues with D3Hot for the
PCI bridges in the Devicetree based platforms. So let's allow the PCI
bridges to go to D3Hot during runtime. It should be noted that the bridges
need to be defined in Devicetree for this to work.

Currently, D3Cold is not allowed since Vcc supply which is required for
transitioning the device to D3Cold is not exposed on all Devicetree based
platforms.

Tested-by: Hsin-Yi Wang <hsinyi@chromium.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/pci.c | 14 +++++++++++++-
 1 file changed, 13 insertions(+), 1 deletion(-)

diff --git a/drivers/pci/pci.c b/drivers/pci/pci.c
index c7a4f961ec28..bc1e1ca673f1 100644
--- a/drivers/pci/pci.c
+++ b/drivers/pci/pci.c
@@ -2992,6 +2992,18 @@ static bool pci_bridge_d3_allowed(struct pci_dev *bridge, pci_power_t state)
 		if (pci_bridge_d3_force)
 			return true;
 
+		/*
+		 * Allow D3Hot for all Devicetree based platforms having a
+		 * separate node for the bridge. We don't allow D3Cold for now
+		 * since not all platforms are exposing the Vcc supply in
+		 * Devicetree which is required for transitioning the bridge to
+		 * D3Cold.
+		 *
+		 * NOTE: The bridge is expected to be defined in Devicetree.
+		 */
+		if (state == PCI_D3hot && dev_of_node(&bridge->dev))
+			return true;
+
 		/* Even the oldest 2010 Thunderbolt controller supports D3. */
 		if (bridge->is_thunderbolt)
 			return true;
@@ -3042,7 +3054,7 @@ bool pci_bridge_d3cold_allowed(struct pci_dev *bridge)
  *
  * This function checks if the bridge is allowed to move to D3Hot.
  * Currently we only allow D3Hot for recent enough PCIe ports on ACPI based
- * platforms and Thunderbolt.
+ * platforms, Thunderbolt and Devicetree based platforms.
  */
 bool pci_bridge_d3hot_allowed(struct pci_dev *bridge)
 {

-- 
2.25.1

