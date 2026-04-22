From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:53 +0530
Subject: [PATCH 12/12] Bluetooth: hci_qca: Fix the broken BT_EN GPIO
 detection for Qcom WCN devices
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-12-720d02545a64@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 stable+noautosel@kernel.org
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=2538;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=MQK4uW+3KV6qGFqWC5yEYOtbmFTmhw+bW5cuFTU5wq0=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6LAWuB2qxpCLf/GFBYjifLzZ8B9XHNP/TnaUg
 6BT6IqwDcqJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFgAKCRBVnxHm/pHO
 9UrGCACcW+dlfQav+XDBsT8HgQvBy6YlJjwgniDIlcAYbGTDuMmfs1PqEWivUb4lfHSSOMkUUAp
 mB+c9oOr7b08WeHiuO6gEtLJx1hITwXtZuJsrWjr5/dMeWwH1uIhIrbQc0XobrppCNb1YtkqPy2
 d34tGCxvjcH+Bzhz1IaNm4kW/FVogCv4LDi3K6zN3yHVVTghJpX8K6ZbuGtl/WcxHoouM4+nRty
 /jzTiLzt2Ax8VKjr19NAR/tStQGbufxp3PK/g6FmNE75k/teM3lF+ujGx52i5s7Cjdd+8CtthCJ
 ffU2AI06ZtQBFJVIFeYP684R9qS+CZYFDcNr1H5dPzJwE7Kk
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit 'db0ff7e15923 ("driver: bluetooth: hci_qca:fix unable to load the BT
driver")' tried to check the presence of the BT_EN GPIO in Qcom WCN devices
to indicate the HCI layer whether this BT device can be power controlled or
not.

But it was broken for two reasons:

1. Assumes that when devm_pwrseq_get() API returns an error, BT_EN is not
controllable. This is no way true as the API can fail for various reasons
and also the pwrseq-qcom-wcn driver treats the BT_EN GPIO as optional. So
even if the GPIO is not present, it will not fail the probe and this API
will not fail.

2. By skipping the error return, probe deferral is completely broken as the
API may return -EPROBE_DEFER to indicate the caller that the pwrseq driver
is not yet probed. Skipping the return value means, this driver is not
going to depend on pwrseq driver probing again and it just assumes that
the pwrseq is not available.

So to fix these issues, fail the probe if devm_pwrseq_get() returns an
error and if it succeeds, use the newly introduced pwrseq_is_fixed() API to
check whether the power sequencer is fixed or not (i.e., whether the
Bluetooth interface on the Qcom WCN device is controllable using BT_EN GPIO
or not) and set the 'bt_en_available' flag accordingly.

Cc: <stable+noautosel@kernel.org> # Depends on pwrseq change
Fixes: db0ff7e15923 ("driver: bluetooth: hci_qca:fix unable to load the BT driver")
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/bluetooth/hci_qca.c | 15 ++++++---------
 1 file changed, 6 insertions(+), 9 deletions(-)

diff --git a/drivers/bluetooth/hci_qca.c b/drivers/bluetooth/hci_qca.c
index 27e52b08ec47..dd1d93cbb3d8 100644
--- a/drivers/bluetooth/hci_qca.c
+++ b/drivers/bluetooth/hci_qca.c
@@ -2470,16 +2470,13 @@ static int qca_serdev_probe(struct serdev_device *serdev)
 			qcadev->bt_power->pwrseq = devm_pwrseq_get(&serdev->dev,
 								   "bluetooth");
 
-			/*
-			 * Some modules have BT_EN enabled via a hardware pull-up,
-			 * meaning it is not defined in the DTS and is not controlled
-			 * through the power sequence. In such cases, fall through
-			 * to follow the legacy flow.
-			 */
 			if (IS_ERR(qcadev->bt_power->pwrseq))
-				qcadev->bt_power->pwrseq = NULL;
-			else
-				break;
+				return PTR_ERR(qcadev->bt_power->pwrseq);
+
+			if (pwrseq_is_fixed(qcadev->bt_power->pwrseq))
+				bt_en_available = false;
+
+			break;
 		}
 
 		qcadev->bt_power->dev = &serdev->dev;

-- 
2.51.0

