From: Juerg Haefliger <juerg.haefliger@canonical.com>
Date: Tue, 13 Oct 2026 17:29:38 +0200
Subject: [PATCH] bus: mhi: host: pci_generic: Add HP Snapdragon X72 5G
 modem support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261013-mhi-add-hp-x72-v1-1-cf26405bf097@canonical.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqDMBBA4avIrDtgxqpNryIubDKaKfhDoiKId
 zfq8lu8t0NgLxzgm+zgeZUg4xChXgkY1wwdo9hooJQKlSrC3gk21qKbcCsJNeXZpzW6LPQbYjR
 5bmW7h1X9OCy/P5v5usBxnPb3IbpyAAAA
X-Change-ID: 20261012-mhi-add-hp-x72-92538fc97694
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Jeff Hugo <jeff.hugo@oss.qualcomm.com>
Cc: mhi@lists.linux.dev, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Juerg Haefliger <juerg.haefliger@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1237;
 i=juerg.haefliger@canonical.com; s=F9F8B48C; h=from:subject:message-id;
 bh=DZhxHHXBj1Cd5Q5l02eE4hIaNt+qOTIa/0lNai/M90U=;
 b=owEBbQKS/ZANAwAKAQ/TiwkLpkK3AcsmYgBqzk5tEkSiTimfSrxvDL0UjYzXjJUAPPoXcAtQb
 /AUP6OlPtSJAjMEAAEKAB0WIQSFl9T3oi6mu+It14sP04sJC6ZCtwUCas5ObQAKCRAP04sJC6ZC
 tySrD/42xTSv+fEcQfXei/nVAWc9gyN6dkQVi2iGyQt0mcfQ97iVnNNq3MHtF8SQhU/9FYFAY8Q
 gtaPMw/14RTder6oF263Ss4csMLtZGwsGMxJ18VPR5P8Dv3gCum7AHo29G79pWbAKoc58o4LY22
 ZmF5WL4TgPtPGQRcE28O2Cx99P2QiHUdMcJ1hCoHhu2zXh+MbJ4ANyuvonaAFaKMWBx9PjpUXDp
 vEIqXt+kFHEOC7m4E2ve7whK7PpwrFN1ehVcgXskAlR8pkGr1j2rUkFHOXB8HyRJVISh316JfIt
 BI9j23dMDj0rVsCHK3IoP0sg38Pcn58FmfP99jCh6MXvAD0TCjZFtgAnoe1QvYRbcWU+PxJ3PRg
 gHGNRbpV7h55Rc9FymgTJ4pSLG+PqvbPNIhlYDQvU59S5hiEPeRdwlLLeB1BP4WeMo2dG4wvOUX
 TVSlnC4pDNo1ZNGyPcIvaFQg4VGd+rsf6xuSXFdeRxWWcktTAYQ/Jg95Rm3/Y/lp7TlFI9ni8Tg
 PFI22j9hWctjECbMPWtrGvAow6OrjIUDcOi9iz/dTTMYBeV7W4jRWjcyDqxFgv2CBHfd7SI0Mss
 RWEbbxDsoTmVq8zq3WuJmOYRKXdlyDAjnfNEI7UeaFd5ST8vOKTQ9j4Cb4WO1jJGTvi63K8Sukk
 ppy1jHduGMXivyg==
X-Developer-Key: i=juerg.haefliger@canonical.com; a=openpgp;
 fpr=52B5BDD2A6EDC76A0FE0AB4A754C3A96F9F8B48C
X-Endpoint-Received: by B4 Relay for juerg.haefliger@canonical.com/F9F8B48C with auth_id=1135
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the PCI ID (103c:8e09) for the HP Snapdragon X72 5G MHI modem found
in HP Snapdragon X laptops such as the HP EliteBook 6 G1q. The modem is
based on the Qualcomm SDX72/SDX75 baseband and uses mhi_qcom_sdx75_info
for controller and channel configuration.

Signed-off-by: Juerg Haefliger <juerg.haefliger@canonical.com>
---
 drivers/bus/mhi/host/pci_generic.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/drivers/bus/mhi/host/pci_generic.c b/drivers/bus/mhi/host/pci_generic.c
index b636e2c23b4d..46cafee39f71 100644
--- a/drivers/bus/mhi/host/pci_generic.c
+++ b/drivers/bus/mhi/host/pci_generic.c
@@ -1082,6 +1082,9 @@ static const struct pci_device_id mhi_pci_id_table[] = {
 	/* NETPRISMA FCUN69 (SDX6X) */
 	{ PCI_DEVICE(PCI_VENDOR_ID_NETPRISMA, 0x1001),
 		.driver_data = (kernel_ulong_t) &mhi_netprisma_fcun69_info },
+	/* HP Snapdragon X72 5G (sdx75) */
+	{ PCI_DEVICE(PCI_VENDOR_ID_HP, 0x8e09),
+		.driver_data = (kernel_ulong_t) &mhi_qcom_sdx75_info },
 	{  }
 };
 MODULE_DEVICE_TABLE(pci, mhi_pci_id_table);

---
base-commit: 705529dab1fa872d8b53b09c95e1b03a95573376
change-id: 20261012-mhi-add-hp-x72-92538fc97694

Best regards,
-- 
Juerg Haefliger <juerg.haefliger@canonical.com>

