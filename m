From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:52 +0530
Subject: [PATCH 11/12] Bluetooth: hci_qca: Check whether the M.2 UART
 interface is fixed or not
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-11-720d02545a64@oss.qualcomm.com>
References: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
In-Reply-To: <20260422-pwrseq-m2-bt-v1-0-720d02545a64@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1019;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=QIQ7zI+FcCO4Ozijr68y6L0R3ZFIXMS+JR88yCNclek=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6LAVR3W3V/KaHFdujOJwfJZ0I+8jLydfeBZ8c
 C328qYFsrOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFQAKCRBVnxHm/pHO
 9YQwB/0SQX+/Rbzc9tYYkKZ8hAXIlBudrTL7cV4f3GeBe+ZtK6NTWCunNb7eXa9yuHvHCd9rl3k
 q3rztVESPA7EUkULnNf3vf69nKap5M8nXd5LoUFcL6F/3b4WhDkUoAPCC4dpT1fYfLR4kqp4k/F
 adD+fVrocmi0ny4WJxDSF31GfJjsi+Hkp23SqSfIOvgcU/d3sTZVro8VRjvt64KXqfbgWf5rZtg
 qhYP9GXbF/4T6a83od1As5/ZPGYlb1DJPYysyepKTx91EWhl78i48qE4wM2oLiMv3ohsqVyqKUy
 B73fONwa5nr+RdRHt8DVLfnQtWt6ukk5yzMGy8jpFxfpcwvG
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

In the M.2 connector, the UART interface is controlled through the
W_DISABLE2# signal. But the BT driver cannot know directly whether this
signal is available or not.

Hence, use the new pwrseq API 'pwrseq_is_fixed()' to check whether the UART
interface on the M.2 connector is fixed or controllable and set the
'bt_en_available' flag accordingly.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/hci_qca.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index 3e71a72ea7c7..27e52b08ec47 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -2453,6 +2453,10 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 								   "uart");
 			if (IS_ERR(qcadev->bt_power->pwrseq))
 				return PTR_ERR(qcadev->bt_power->pwrseq);
+
+			if (pwrseq_is_fixed(qcadev->bt_power->pwrseq))
+				bt_en_available = false;
+
 			break;
 		}
 

-- 
2.51.0

