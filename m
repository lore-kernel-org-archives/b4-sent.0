From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 07 May 2026 21:36:17 +0530
Subject: [PATCH v2 9/9] Bluetooth: hci_qca: Set 'bt_en_available' based on
 W_DISABLE2# presence in M.2 connector
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-pwrseq-m2-bt-v2-9-1740bd478539@oss.qualcomm.com>
References: <20260507-pwrseq-m2-bt-v2-0-1740bd478539@oss.qualcomm.com>
In-Reply-To: <20260507-pwrseq-m2-bt-v2-0-1740bd478539@oss.qualcomm.com>
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Shuai Zhang <quic_shuaz@quicinc.com>
Cc: linux-pm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-pci@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-bluetooth@vger.kernel.org, Wei Deng <wei.deng@oss.qualcomm.com>, 
 Luiz Augusto von Dentz <luiz.von.dentz@intel.com>, 
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1280;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=kT/daCATvUeblQjstk/xz8aGuQ4+x8sVK/KhZTDC6as=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp/Lh3qBHbqcZIzl+5YqO+PrOKii2iHINB9NljG
 TRznrWuJaGJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCafy4dwAKCRBVnxHm/pHO
 9dQAB/9HaNIKcu7vecDN+DH8+r+PzhQyxhZlVjgokj6XPnBAtQXxdPZn699QwTXKoypwr4XcS65
 2J+gS2k8DRc3GVP3nADCvi0rLacpymyyucsPKiAmZGVXOn24XH6YDzhoO3ki4OUyfsb+D7D7GbR
 E2e8KpXCaVg94siJVNbfD9z+U6fyUEQvJ3G5vG0+DN4wcNxD9huMPcL74NCw+6eYjfy7Pwyo2VI
 6hf6age9p8eUQ+OriJXToL6Dt0nQjzSBbVUNpnMCKZc7CgCgbSQfGRJZw1ZeAy62ADFx7cgdm9i
 2yfrUrQ9Mfhm29bBqDTYgAHGqMWqkxmqF7A5IFBI/YzDbZUK
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Check if the M.2 connector supports the W_DISABLE2# property or not by
querying the pwrseq provider's DT node. If not available, then set
'bt_en_available' flag to 'false'. This flag is used to set the
HCI_QUIRK_NON_PERSISTENT_SETUP HCI quirk, which informs the HCI layer
whether the shutdown() callback for the device can be triggered or not.

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
2.51.0

