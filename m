From: David Heidelberg <david@ixit.cz>
Date: Wed, 11 Mar 2026 19:44:30 +0100
Subject: [PATCH 2/2] arm64: dts: qcom: sdm845-xiaomi-beryllium-tianma:
 Disable MDSS
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260311-beryllium-fb-v1-2-408a580d125e@ixit.cz>
References: <20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz>
In-Reply-To: <20260311-beryllium-fb-v1-0-408a580d125e@ixit.cz>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Heidelberg <david@ixit.cz>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=960; i=david@ixit.cz;
 h=from:subject:message-id; bh=3Pg7NvtymOOJ0LjoaS8anANtqZcNQW66vxuq+tyshlk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpsbgOFN0ReCshfufGyULOQf7EZRyQs3GVsHVb9
 K1qGZUzGRGJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCabG4DgAKCRBgAj/E00kg
 ciqKD/wMixPocS60DrqpLPI/mYEJMYSsKvfDAZ28XU7nRLtzXMaKEeJC+q1g0AT3IV9Hl1Ygysw
 SRuhlexk2kRycUualbhyrVMDe4GraTrbUGv1tW7dNTe/yKaizDeI41eXPuk47hQUPz/EtH8ZlfM
 XVY2JfbG4rjxzmzNE7OUM3FiXmd0IXZj7njHiLAbn78811CYfbgTIQZwwb6tQysE+Z48jBu7jdx
 4bNrrzsPmeFin0kNutgsOblQUw9qO8bnYlwk54jM2Ds/bDCN68arPGK+N9kE6zVTPC9Mg8wMQbh
 mUCm4AA0DL873Zl7rK12NDEzAafQHG0hrG5fRR+u5zQd4F017o8RIOt9AF4JUTUIXCxgs7LVDFP
 c//aaFd25kXCkRGeUjmmEIBBfemvKitvPJZNq+qqPGPPFFzTeOcPqR6gWdjaWo1LoKMBCxp8U/p
 AScPU3CoaWggcLY/6yGxdG5zGCF5mkohNZAlH39oud2sJU2WB/Ewi+EqpPkV2mEORJzXe8x5R3r
 PHII+f2z8tI26KJvDa8y5UZ/RQAZgcbXe95GctyZ/wsIs4dtdqsSnMFSvhh6b4saHDNe+79IyOA
 YyeiGv5sa6bLUswQghRJQDvMD05X4pYEE4DqvYW92ZPwo1iFZoJTvpuPyZjaiKBcDQTCl4q97eJ
 HtJLiZeIPkb+foQ==
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

