From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Tue, 19 May 2026 14:26:04 +0530
Subject: [PATCH v3 9/9] Bluetooth: hci_qca: Set 'bt_en_available' based on
 W_DISABLE2# presence in M.2 connector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260519-pwrseq-m2-bt-v3-9-b39dc2ae3966@oss.qualcomm.com>
References: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
In-Reply-To: <20260519-pwrseq-m2-bt-v3-0-b39dc2ae3966@oss.qualcomm.com>
To: Manivannan Sadhasivam <mani@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>
Cc: linux-pci@vger.kernel.org, linux-pm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1402;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=qhYeDGRs7g3L5EI4vL/aBNiOeNbObMwLbx4vbZzrq4Q=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBqDCWgT26G56u8CFC6bzeX+drLEj2zvQzXmY9jU
 Ldhw5Am9Y6JATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCagwloAAKCRBVnxHm/pHO
 9XLYB/4gTkNUgoM4H4MF6p4LmyPBauiswNdCgjlccfcY7i4nsCjefKTFkCwyGS2kjZUzRiWRzlk
 MRoPpLy+UF+2gHLZImAf0I/eKE37gB8dUYMeDme7citmtk9fDw4R9ZX1n3Zkr59o8it+O9m59oY
 FSSF/sm2JojrXmwYB7063rwZ+Sfz7AvBz9sszDk8oLqKZRYrdRtKa8fjXz1SlalZ2k+ATxAn1xR
 qE8oFx1w6OFHFjtX1fCIEqbs3MB30RErWMXG+icMfTFSdoJep4mmPgguahcQdrThM1AT1eZJp21
 yL05JLFNZ+JT2XpeHboyj91u/DTNbcczWJOF7lxVz+HRBjrT
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check if the M.2 connector supports the W_DISABLE2# property or not by
querying the pwrseq provider's DT node. If not available, then set
'bt_en_available' flag to 'false'. This flag is used to set the
HCI_QUIRK_NON_PERSISTENT_SETUP HCI quirk, which informs the HCI layer
whether the shutdown() callback for the device can be triggered or not.

Tested-by: Wei Deng <wei.deng@oss.qualcomm.com>
Reviewed-by: Bartosz Golaszewski <bartosz.golaszewski@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/hci_qca.c | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index 3e71a72ea7c7..b5439b9956cf 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -2449,10 +2449,17 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 		 * the M.2 Key E connector.
 		 */
 		if (of_graph_is_present(dev_of_node(&serdev->ctrl->dev))) {
+			struct device *dev;
+
 			qcadev->bt_power->pwrseq = devm_pwrseq_get(&serdev->ctrl->dev,
 								   "uart");
 			if (IS_ERR(qcadev->bt_power->pwrseq))
 				return PTR_ERR(qcadev->bt_power->pwrseq);
+
+			dev = pwrseq_to_device(qcadev->bt_power->pwrseq);
+			if (!device_property_present(dev, "w-disable2-gpios"))
+				bt_en_available = false;
+
 			break;
 		}
 

-- 
2.48.1

