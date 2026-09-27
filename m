From: George Moussalem <george.moussalem@outlook.com>
Date: Sun, 27 Sep 2026 08:42:56 +0400
Subject: [PATCH] arm64: dts: qcom: ipq5018: add label to PCIe1 port node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260927-ipq5018-pcie1-label-v1-1-41f7d42f9a7b@outlook.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBA0avErBtQqayuEi1MxxqIMoUIwrsnL
 d/i/xcSRaYEY/VCpJsTn0eBrCuwmzlWQnbFoITqxKA0crhaIXsMlknibhba0WnXiNYar3oPpQy
 RPD//dZpz/gASTcSSZQAAAA==
X-Change-ID: 20260927-ipq5018-pcie1-label-d7d405caf28f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790484176; l=1071;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=HNZl3Aso7KY3/rmD1u9y6FFgvwtYVcoDQZoiHKmM2AM=;
 b=ikHgmUVE3MQ8T0uEHdvr3Kvn0mVtTALISk/rbJhf/noKsJdYIT+aTLveg+c7YpC0WCtwDBT3Y
 Cw0+cUSG4rRCfBAzuhSK2CIXSPiLW/giSbVojs0RGj03x5CmcRoQlSI
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Commit a95758e9718a ("arm64: dts: qcom: ipq5018: move PCIe phys and
PERST# to port node") added a label to the PCIe0 port node but not to
that of PCIe1. Boards that have a device connected over PCIe1 need to
reference the port node in the board dts files, so add a label for it.

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
 arch/arm64/boot/dts/qcom/ipq5018.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/ipq5018.dtsi b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
index fe1ed240de59..2f3bcfa888a9 100644
--- a/arch/arm64/boot/dts/qcom/ipq5018.dtsi
+++ b/arch/arm64/boot/dts/qcom/ipq5018.dtsi
@@ -838,7 +838,7 @@ pcie1: pcie@80000000 {
 
 			status = "disabled";
 
-			pcie@0 {
+			pcie1_port0: pcie@0 {
 				device_type = "pci";
 				reg = <0x0 0x0 0x0 0x0 0x0>;
 				bus-range = <0x01 0xff>;

---
base-commit: f5f84daefcd92d7a630066635ecea1433ed5eac7
change-id: 20260927-ipq5018-pcie1-label-d7d405caf28f

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

