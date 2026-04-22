From: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
Date: Wed, 22 Apr 2026 16:54:43 +0530
Subject: [PATCH 02/12] power: sequencing: pcie-m2: Add support for
 'is_fixed()' callback to 'uart' target
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260422-pwrseq-m2-bt-v1-2-720d02545a64@oss.qualcomm.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1269;
 i=manivannan.sadhasivam@oss.qualcomm.com; h=from:subject:message-id;
 bh=KrtcCm7OcSv08XpTnM/lQ/uL0Jkw1/hkwY8pIBjRoGw=;
 b=owEBbQGS/pANAwAKAVWfEeb+kc71AcsmYgBp6LAUHpCgMluCaUwOrCltzrJ6ja/gcCe4jKxCe
 rrgJaYjXUOJATMEAAEKAB0WIQRnpUMqgUjL2KRYJ5dVnxHm/pHO9QUCaeiwFAAKCRBVnxHm/pHO
 9Q1fB/9YdhK57pITNVRy/bWS9zw1nLMkSCIl1c9LaHMyPWQl+jBVvrhgMJvyuGZVFrDFUdXjoDj
 mjyPROGFEv9J2oYrtv/9RRz96bujgr7l55UtBwkc3AykDGQEYw8c0wWVUrnhpDD9DhzwZxrYJlH
 UpNIj1l/cU8a7xyUzg1kn5IPEIPe8SnGxNPMz1uRIs853ozxAq885PAMZ82uxJSFVsiKiEVwMJQ
 gpR8Vbl1ep2SwszXzShwqEgqcK1QeRrOFgk0pZeVFnrmgzevKnn7RlAqOLEiet30EUiJ98f47O8
 Oir94HPSNehL9jijUIksuWgaYhLOLF5X1qHe3w0y9X7Rvlr4
X-Developer-Key: i=manivannan.sadhasivam@oss.qualcomm.com; a=openpgp;
 fpr=C668AEC3C3188E4C611465E7488550E901166008
X-Endpoint-Received: by B4 Relay for manivannan.sadhasivam@oss.qualcomm.com/default with auth_id=461
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for 'is_fixed()' callback to tell the consumers whether this
power sequencer target 'uart' is fixed or controllable. This is decided
based on the availability of the 'W_DISABLE2#' GPIO in DT.

Signed-off-by: Manivannan Sadhasivam <manivannan.sadhasivam@oss.qualcomm.com>
---
 drivers/power/sequencing/pwrseq-pcie-m2.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/drivers/power/sequencing/pwrseq-pcie-m2.c b/drivers/power/sequencing/pwrseq-pcie-m2.c
index ef69ae268059..2b79f2e34079 100644
--- a/drivers/power/sequencing/pwrseq-pcie-m2.c
+++ b/drivers/power/sequencing/pwrseq-pcie-m2.c
@@ -121,10 +121,18 @@ static int pwrseq_pcie_m2_e_pwup_delay(struct pwrseq_device *pwrseq)
 	return 0;
 }
 
+static bool pwrseq_pcie_m2_e_uart_is_fixed(struct pwrseq_device *pwrseq)
+{
+	struct pwrseq_pcie_m2_ctx *ctx = pwrseq_device_get_drvdata(pwrseq);
+
+	return !ctx->w_disable2_gpio;
+}
+
 static const struct pwrseq_target_data pwrseq_pcie_m2_e_uart_target_data = {
 	.name = "uart",
 	.unit = &pwrseq_pcie_m2_e_uart_unit_data,
 	.post_enable = pwrseq_pcie_m2_e_pwup_delay,
+	.is_fixed = pwrseq_pcie_m2_e_uart_is_fixed,
 };
 
 static const struct pwrseq_target_data pwrseq_pcie_m2_e_pcie_target_data = {

-- 
2.51.0

