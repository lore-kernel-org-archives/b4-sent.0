From: David Heidelberg <david@ixit.cz>
Date: Tue, 18 Mar 2025 13:51:21 +0100
Subject: [PATCH] ARM: dts: qcom: apq8064-lg-nexus4-mako: Enable WiFi
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250318-lg-nexus4-mako-enable-wifi-v1-1-e3b4a09d9f68@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAEhs2WcC/x3MQQqDMBAF0KvIrDtgbCLaqxQXaf3RQY0lQRsQ7
 25w+TbvoIggiPQqDgrYJcrqM9SjoO9o/QCWPpuqsjLlUzU8D+yRtqh5sdPK8PYzg//ihF2ttOp
 hnDYt5eAX4CTd+bs7zwvgKhRMbAAAAA==
X-Change-ID: 20250318-lg-nexus4-mako-enable-wifi-f6141de5f459
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1456; i=david@ixit.cz;
 h=from:subject:message-id; bh=oABHqPk0qYz8RHZ1DC5dvgMY1GAwB6itVi5XXv+ltKE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn2WxNl/rCFHhm/Y68tSJ93r3SbPWxEGpVqZXRR
 VidrDnbnHuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ9lsTQAKCRBgAj/E00kg
 cpydD/kB9AOtHCkPb46KSrycSfDhrrEVqRYmu8HiNksmTk8E2eiz1vddb3eTx4YlwDlsxG1VlsM
 tK8s1tSAPcJvHS5bmpf9XNyXyUypW9CpX0r0Anqe08gAtN6tqc7yfArpDoIpD/QbNC6cEnb93wH
 6RutXonQxADYkZ/qhsUQfksMKJ6fSsJlKdrStbnLorr4g1T9hgH3kjn6AWBkvL30nQC/MT4bdsG
 /Ed/JT036EfrjgNFQSDiWPz9rwIkoB0k0bi4Lad9CZ0lBZTH0I67RgE+kPpNPblPzwP+sFs6oJM
 geEssK7HXyerGA3H/ztyPFFacgjh+zm2Hz7ZxtpKYEJ6dxksMjuz9NtnZb8/WEZDS+6PsfpBtr4
 XmTYJ385uTZQ3h2sh4RTQz1GxDuqPVu1PHo0Elt3953Jiq/676z5oVmvYWrHEmcKhedprglbjtZ
 jI2qF9AeIyFxfnGpBMD/Nph+cyT9zMGIL8i4giMiWw2iDW6G7Ui+gM7Je8XEVCh18fhtyuKsirJ
 PUtZCzW12geS25rvorGisoG2yqDTPI9qm228SwWiaBn7p8BGxRXwEncEmDO6GIlSn6OezuHbpf1
 sKQFdRbj08flbkdVHr7b7mIW8CaxdaxEJB1ZR3NYAJHoc3IR9RPlz3H8CneAEKZPm70L1tje1Z8
 xyeM7n0xjPQKWKg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Wi-Fi setup is identical to that of the Sony Xperia Z (Yuga).

Verified against the legacy kernel configuration inside
 arch/arm/mach-msm/board-8064-regulator.c
using LineageOS 14.1 kernel sources.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm/boot/dts/qcom/qcom-apq8064-lg-nexus4-mako.dts | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-apq8064-lg-nexus4-mako.dts b/arch/arm/boot/dts/qcom/qcom-apq8064-lg-nexus4-mako.dts
index 5710450faabf34fa5991d8803a2369cfbb09e4ea..c187c6875bc69d6ad711b52d519fe6a2660f09be 100644
--- a/arch/arm/boot/dts/qcom/qcom-apq8064-lg-nexus4-mako.dts
+++ b/arch/arm/boot/dts/qcom/qcom-apq8064-lg-nexus4-mako.dts
@@ -86,6 +86,24 @@ MATRIX_KEY(0, 1, KEY_VOLUMEUP)
 	status = "okay";
 };
 
+&riva {
+	pinctrl-names = "default";
+	pinctrl-0 = <&riva_wlan_pin_a>, <&riva_bt_pin_a>, <&riva_fm_pin_a>;
+
+	vddcx-supply = <&pm8921_s3>;
+	vddmx-supply = <&pm8921_l24>;
+	vddpx-supply = <&pm8921_s4>;
+
+	status = "okay";
+
+	iris {
+		vddxo-supply = <&pm8921_l4>;
+		vddrfa-supply = <&pm8921_s2>;
+		vddpa-supply = <&pm8921_l10>;
+		vdddig-supply = <&pm8921_lvs2>;
+	};
+};
+
 &rpm {
 	regulators {
 		compatible = "qcom,rpm-pm8921-regulators";

---
base-commit: c4d4884b67802c41fd67399747165d65c770621a
change-id: 20250318-lg-nexus4-mako-enable-wifi-f6141de5f459

Best regards,
-- 
David Heidelberg <david@ixit.cz>

