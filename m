From: David Heidelberg <david@ixit.cz>
Date: Mon, 06 Apr 2026 22:18:25 +0200
Subject: [PATCH v2] arm64: dts: qcom: sdm845-oneplus: Enable known blocks
 and add placeholders
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260406-placeholders-v2-1-9cdbe1fc9666@ixit.cz>
X-B4-Tracking: v=1; b=H4sIABAV1GkC/1XMywrCMBCF4VcpszaSjLmoK99DugjJaAZKW5JSq
 qXvbqwrl/+B861QKDMVuDYrZJq58NDXwEMDIfn+SYJjbUCJRik8ibHzgdLQRcpFuGgN4cXqs9d
 QL2OmBy87d29rJy7TkF+7Pqvv+oNQ2X9oVkKJ6KLRGqUkF2688HQMb2i3bfsA/AJQMaYAAAA=
X-Change-ID: 20251123-placeholders-7d65e29648a4
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1563; i=david@ixit.cz;
 h=from:subject:message-id; bh=AVzwMsW29OzyZogD7/oC7WV7gAZxzBH+SW2iQDHGVNU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp1BU7glHYvyVib5voHAAb05fXLjKUjKvkSXEBO
 JhQ91xt4hOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCadQVOwAKCRBgAj/E00kg
 cucJD/9M5lIqwyWqQrriy8WD8qm4T3QiE/Vd0fCadR4Rmi1RR6p/Q6n+MLu+XWpbHyYGJdTcHon
 xEGMR6wMAf7f2EgbNZdJIlaXHTQXDd8qMuW1VYd5U8NwQG9RgBb3nmmRtYkdD9rUomWXkpVoetV
 MCOIG5oHo4133DR6cxXXA5f4Z0jr+XeQzxgI92UHxR+KHMB8lbeiHr+JuJRDdJMfM2Vk/n3h0/u
 XxnulhAVr7zCb5/+BtaDgsnRPJpO9mhP28rCBPSiFWEu7vnPSszOY8XfRf1r8UpT0z/DVj79qLS
 HL6NarB2BgqqsljBtrLQ1sVU8jaJWG3ihEvA5lftgf/21fcc737tyCkTSb3z79TdQ9iaKRRF3SH
 Gx0JXHWuanre5TvR8sz5bDAjTeGibhCxGoMEztvcRLH2TGUbPWRttXm97rx/eYBB1LcnlgmP0wU
 8G5F7RYEiiEEAnTrtazGSLABsAsE96+mvosm4+GMnr4ckOjseSdUHB2dgQYUdvegeLK8pyKUOVw
 tPT5hJlQpBZbKCaImiJ7zaUM7vBOCf7iaJZjPn4pl9l6VdsKiLgI9e5ZF3Zo2yx40xEnw7ODlWX
 gfo3TkW3gO0u5/cp6jyRVgCUMoX81StLTCmvhxnRo1NejUg13SsFbld7u/TPDDeCp7HmSoPbRE+
 0dxTez1sv0XbJiQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We know these devices are present; most of them are supported by
downstream and are close to the mainline kernels.

This adds placeholders for:
 - front camera (imx371)
 - rear cameras (imx519, imx376k)
 - actuators

This is very handy when rebasing the integration tree with
support for multiple different blocks at the same time.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Dropped NFC placeholder, as the series for NFC support has been sent
  upstream.
- Link to v1: https://lore.kernel.org/r/20251216-placeholders-v1-1-d7d544200e7c@ixit.cz
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
index 6b7378cf4d493..719d98240a21d 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi
@@ -442,6 +442,26 @@ vreg_s3c_0p6: smps3 {
 	};
 };
 
+&cci {
+	status = "okay";
+};
+
+&cci_i2c0 {
+	/* front sony,imx371 @10 */
+
+	/* rear sony,imx519 @1a */
+
+	/* rear onnn,lc898217xc @72 */
+};
+
+&cci_i2c1 {
+	/* sa,sa3103 @0d */
+
+	/* rear sony,imx376k @10 */
+
+	/* onnn,lc898217xc @74 */
+};
+
 &cdsp_pas {
 	firmware-name = "qcom/sdm845/OnePlus/enchilada/cdsp.mbn";
 

---
base-commit: 816f193dd0d95246f208590924dd962b192def78
change-id: 20251123-placeholders-7d65e29648a4

Best regards,
-- 
David Heidelberg <david@ixit.cz>

