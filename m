From: David Heidelberg <david@ixit.cz>
Date: Tue, 17 Mar 2026 23:12:35 +0100
Subject: [PATCH v2 5/5] arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma:
 Disable MDSS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260317-beryllium-fb-v2-5-36b69dfb760c@ixit.cz>
References: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
In-Reply-To: <20260317-beryllium-fb-v2-0-36b69dfb760c@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>, 
 Sam Day <me@samcday.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=960; i=david@ixit.cz;
 h=from:subject:message-id; bh=3Pg7NvtymOOJ0LjoaS8anANtqZcNQW66vxuq+tyshlk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpudHR0dYPx2NAiTEfwG9J2cJNYLUHEIUq2Fqrr
 p9dyPncKZaJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabnR0QAKCRBgAj/E00kg
 cgj0EACvjR2Ds4u6CWeByHcVIabwWqa5Ly6NdWfhFeXL3uuKD38KDCa5nBLIB4W1CKbGJBRKfaq
 8KYEjGW3H31ePbPLayVGHvNdTn73Y+vlMffFP4tP83ulyG4Dr3C630nmUqbEpXwWXKNpZkLwXRT
 GnSW48Nt+QJjQnrOi4vMZKJMYl2q6A4n0UdJgXNaZP32jtaPyOpt3d14T6GRGQPnReGgQFTfT38
 btkGY6SKOtlPL8dNxLS9aHFKb8ZaPH8YsQiDm2nHHtNP+kZy/nJH6k8zG8k38g/Eadaf5P29qER
 pozHIpixetaB4Z7MEZwByZbtbG884BCItGQz66iMCYP7uazdfot8x7FyTNBOOL1dy52HR4qejLH
 4dYmKYvKjEDq9O+Celt3IeBPbqC1HbXs9VoJNRlfuthWHBicqlUHPZaIY7jrY5uk/jwJUW6dNUd
 4XzkswT3nx/WC2AagO8gagQTovfHLJJktieujrHUuA0JYz4OPuLkD6X4hDTUELvpvUcel7tUdyF
 ExYk+Tdax9uH02Xf1IOo/bjz5pnlS7jXpL6M2KV8XNNocKS7zFTq6KUETeF4lu1KHWw8vsaoG81
 L2bQOfbvRbkjxPx82qDAaaZQr21ngVgPpWLV04AjgYWBjI0JTaWksPimneVJZgnlX30Uc9tOdpN
 C0bXxrbeTCPH65Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Petr Hodina <petr.hodina@protonmail.com>

Currently the panel driver for tianma is broken.
Disable MDSS to prevent DRM taking over the framebuffer.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
index b58964cde8342..d1c7bccaab500 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-tianma.dts
@@ -36,3 +36,13 @@ touchscreen@1 {
 		touchscreen-size-y = <2246>;
 	};
 };
+
+&dispcc {
+	/* Disable for now so simple-framebuffer continues working */
+	status = "disabled";
+};
+
+&mdss {
+	/* Disable for now so simple-framebuffer continues working */
+	status = "disabled";
+};

-- 
2.53.0

