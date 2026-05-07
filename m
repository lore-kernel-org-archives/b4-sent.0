From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Thu, 07 May 2026 21:36:11 +0530
Subject: [PATCH v2 3/9] power: sequencing: pcie-m2: Improve PCI device ID
 check
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260507-pwrseq-m2-bt-v2-3-1740bd478539@oss.qualcomm.com>
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
 Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1781;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=8A3jxl2QdUuP5KU+w9PLhgemuGtALcmy2NxpKxBwBT8=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp/Lh2TDAvxxjvZtrtADHQF0z/JDOamCojQkHE3
 K6Pm1DtPTiJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCafy4dgAKCRBVnxHm/pHO
 9cVzB/4ohIU0XRnYHWB45I0Mwpu/iTt83ZvLI0NFytSIkWBMwDHYlx9EkFrdH/T72dd/E4zxGei
 K+WfR12Kj1+DuU1DcqXoVyqIAb6QgGIMGaG9VfINxANB671iUD9iPM3da9npdv7WvVv7d1VGGbw
 mVDUp4hXCn65H38uKafSYfx9shPz4YZyy7kQgZdQPXnlgpo9JSceJUBHNZSwYzzArwnsd57n9of
 5+MgPX+wKrpBO1gE18f01B5rgSCb0ZrZIOlaVtEThLfaxP7KoQ3FZABL7GPgyknQo4ANPsefYSG
 oquofbqKA8Orr4CcbIfFVh7xZNBsEmbgrATbRfzFkHmxLVXU
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Instead of hardcoding the PCI device check, use pci_match_id() to check for
the known IDs using the pwrseq_m2_pci_ids[] array.

This makes adding support for new devices easier.

Reviewed-by: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 11 +++++++----
 1 file changed, 7 insertions(+), 4 deletions(-)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index 469e130330fa..038271207a27 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -343,6 +343,11 @@ static void pwrseq_pcie_m2_remove_serdev(struct pwrseq_pcie_m2_ctx *ctx,
 	mutex_unlock(&ctx->list_lock);
 }
 
+static const struct pci_device_id pwrseq_m2_pci_ids[] = {
+	{ PCI_DEVICE(PCI_VENDOR_ID_QCOM, 0x1107) },
+	{ } /* Sentinel */
+};
+
 static int pwrseq_pcie_m2_notify(struct notifier_block *nb, unsigned long action,
 			      void *data)
 {
@@ -362,16 +367,14 @@ static int pwrseq_pcie_m2_notify(struct notifier_block *nb, unsigned long action
 
 	switch (action) {
 	case BUS_NOTIFY_ADD_DEVICE:
-		/* Create serdev device for WCN7850 */
-		if (pdev->vendor == PCI_VENDOR_ID_QCOM && pdev->device == 0x1107) {
+		if (pci_match_id(pwrseq_m2_pci_ids, pdev)) {
 			ret = pwrseq_pcie_m2_create_serdev(ctx, pdev);
 			if (ret)
 				return notifier_from_errno(ret);
 		}
 		break;
 	case BUS_NOTIFY_REMOVED_DEVICE:
-		/* Destroy serdev device for WCN7850 */
-		if (pdev->vendor == PCI_VENDOR_ID_QCOM && pdev->device == 0x1107)
+		if (pci_match_id(pwrseq_m2_pci_ids, pdev))
 			pwrseq_pcie_m2_remove_serdev(ctx, pdev);
 
 		break;

-- 
2.51.0

