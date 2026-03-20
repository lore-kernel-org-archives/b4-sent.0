From: David Heidelberg <david@ixit.cz>
Date: Fri, 20 Mar 2026 18:33:11 +0100
Subject: [PATCH v2] arm64: dts: qcom: sdm845-xiaomi-beryllium: Mark l1a
 regulator as powered during boot
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260320-beryllium-booton-v2-1-931d1be21eae@ixit.cz>
X-B4-Tracking: v=1; b=H4sIANaEvWkC/32NQQ6CMBBFr0JmbQ1TohRX3sOwaMsokyA1bW1A0
 rtbOYDL95L//gaBPFOAS7WBp8SB3VxAHiqwo54fJHgoDLKW57pBKQz5dZr4/RTGuehmoQcjUZF
 tSSoos5enOy978tYXHjlE59f9IeHP/oklFChOnVWNNh2aVl154Xi0H+hzzl9WmZdsrgAAAA==
X-Change-ID: 20260312-beryllium-booton-adb218ec7e28
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amit Pundir <amit.pundir@linaro.org>, 
 Joel Selvaraj <foss@joelselvaraj.com>
Cc: Konrad Dybcio <konradybcio@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1322; i=david@ixit.cz;
 h=from:subject:message-id; bh=qhSNX+ZRoU8k5wfUWkwoB33o7SNAMBW2ljNv0axP1vU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpvYTXzZhy//JiuZ4qBP2RKD13XDkw9Mld4KDoo
 IAzTSF/WSeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCab2E1wAKCRBgAj/E00kg
 chFMD/sEb5fXRORc/goYsqlAANIb4gpgIcgOeicvR1ooTpnhKWoctaeLtjCyWvphycHnE7+aBCA
 kAQND6PZVMFmfhQlvbbAg8Y9swz9muDhi3e85XneSh/ThRE/bfphWTuDUw+F8/TUMmFkXEv2wTr
 NrlyMCx+yfAcALO/j7n5YHHupzXhS+1rSBnSf5AyHRqdXEkFj1SgYOeeWcMiQdGYg0Tw+QwX36P
 4zlcoIl0e+LkMK28nIY452Mom9bJLslS+BPM/TC6PGp5dcytVCX+n0vhmAjM0ISFg4zGqplhcAX
 yyWTu9xr1B2ptmypyneG+dbXs3QOLrGXEfeEN46NXr6Uo5tO/Rq9yJB5OEvbVy5jXz4IyuEshZ2
 vvY4CrUvuEmRf5wTrBJmPaSexjt1G3HS7DPVLJ9AACYkic78tn9wvfeK2AoUZbaT/TozvCfPmOf
 gJwxJAxFkQjG3Z7A7WFPO3OKLzlsR48ymL/GKBeC2YP+VOGk0LcGC8Hh3T0bc6ImOVIKUUKYZ2k
 BXMTJ94uuWh+DG8kXtu3u/Y5cpcGtUaa4Xdm2Q3QweWI/7ykj3HxoseJZnaC22buHVRwI7WPoir
 +/Cgg52gR+UZ1D1AQUyfWIikhBlgVyiowrbAteMdEo+P6X+xMuJ+YMIZkZJRCFkLGoSahYuIRFF
 smGjavlr/9lt6Zg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The regulator must be on, since it provides the display subsystem and
therefore the bootloader had turned it on before Linux booted.

Fixes: 77809cf74a8c ("arm64: dts: qcom: Add support for Xiaomi Poco F1 (Beryllium)")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Filled missing device in the commit subject.
- Fixed commit wording to be more clear. (Konrad)
- Link to v1: https://lore.kernel.org/r/20260312-beryllium-booton-v1-1-59c83ab91b78@ixit.cz
---
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
index 01b570d0880d6..1298485c42142 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi
@@ -148,6 +148,7 @@ vreg_l1a_0p875: ldo1 {
 			regulator-min-microvolt = <880000>;
 			regulator-max-microvolt = <880000>;
 			regulator-initial-mode = <RPMH_REGULATOR_MODE_HPM>;
+			regulator-boot-on;
 		};
 
 		vreg_l5a_0p8: ldo5 {

---
base-commit: 785f0eb2f85decbe7c1ef9ae922931f0194ffc2e
change-id: 20260312-beryllium-booton-adb218ec7e28

Best regards,
-- 
David Heidelberg <david@ixit.cz>

