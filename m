From: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
Date: Fri, 02 Aug 2024 11:25:00 +0530
Subject: [PATCH v5 1/4] PCI/portdrv: Make use of pci_dev::bridge_d3 for
 checking the D3 possibility
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-pci-bridge-d3-v5-1-2426dd9e8e27@linaro.org>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1613;
 i=manivannan.sadhasivam@linaro.org; h=from:subject:message-id;
 bh=yht1diuW60Yop5/MJv61ZmShJUebX/GlA7kDcmFMjJk=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBmrHTC/WwYy2qeJjZ533ltqs4myHg2ephLfnjaa
 88YaDf3/OaJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCZqx0wgAKCRBVnxHm/pHO
 9ajrCACDX9M1OQiUvAHCdt5y/BA9vHawznd1tH4hTb3nJK8n/6kNEfLMDhmwA8MSkNfE1c9v9lj
 ECeeyKSLzwztu4Fi1/mgf2sK1UZwHrhTz3aozN4Ll7G13WXkMBYTtKHniV+vZXpVX/BV25rZR8y
 saJbDjOS+H6g8iiydB32M1mvUN/bZLE48kWjT+FPw5sHKsOCVIAlY4WzcXNeUnuO6k6i0K4XaZx
 KiNj7YAr0GUinezr9e1e9zeJgzPry+a6FWPaZ6hY8vgOThxKPOvQRtt2U/MV0O/ibEVHYnEjG52
 jfv65jm1/C5VMXdRKjTSndaSQKRVp8UIcpA69FZiEA0bMaR1
X-Developer-Key: i=manivannan.sadhasivam@linaro.org; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@linaro.org/default with auth_id=185
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

PCI core is already caching the value of pci_bridge_d3_possible() in
pci_dev::bridge_d3 during pci_pm_init(). Since the value is not going to
change, let's make use of the cached value.

Tested-by: Hsin-Yi Wang <hsinyi@chromium.org>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@linaro.org>
---
 drivers/pci/pcie/portdrv.c | 6 +++---
 1 file changed, 3 insertions(+), 3 deletions(-)

diff --git a/drivers/pci/pcie/portdrv.c b/drivers/pci/pcie/portdrv.c
index 14a4b89a3b83..1f02e5d7b2e9 100644
--- a/drivers/pci/pcie/portdrv.c
+++ b/drivers/pci/pcie/portdrv.c
@@ -702,7 +702,7 @@ static int pcie_portdrv_probe(struct pci_dev *dev,
 	dev_pm_set_driver_flags(&dev->dev, DPM_FLAG_NO_DIRECT_COMPLETE |
 					   DPM_FLAG_SMART_SUSPEND);
 
-	if (pci_bridge_d3_possible(dev)) {
+	if (dev->bridge_d3) {
 		/*
 		 * Keep the port resumed 100ms to make sure things like
 		 * config space accesses from userspace (lspci) will not
@@ -720,7 +720,7 @@ static int pcie_portdrv_probe(struct pci_dev *dev,
 
 static void pcie_portdrv_remove(struct pci_dev *dev)
 {
-	if (pci_bridge_d3_possible(dev)) {
+	if (dev->bridge_d3) {
 		pm_runtime_forbid(&dev->dev);
 		pm_runtime_get_noresume(&dev->dev);
 		pm_runtime_dont_use_autosuspend(&dev->dev);
@@ -733,7 +733,7 @@ static void pcie_portdrv_remove(struct pci_dev *dev)
 
 static void pcie_portdrv_shutdown(struct pci_dev *dev)
 {
-	if (pci_bridge_d3_possible(dev)) {
+	if (dev->bridge_d3) {
 		pm_runtime_forbid(&dev->dev);
 		pm_runtime_get_noresume(&dev->dev);
 		pm_runtime_dont_use_autosuspend(&dev->dev);

-- 
2.25.1

