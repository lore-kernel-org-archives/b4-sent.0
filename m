From: Marko Zidaric <darkobas@gmail.com>
Date: Tue, 24 Nov 2026 22:51:11 +0100
Subject: [PATCH] arm64: dts: qcom: glymur-lenovo-yoga-slim7x: Enable
 SMB2370_2
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261124-yoga-slim7x-smb2370-v1-1-2656ec0226e7@gmail.com>
X-B4-Tracking: v=1; b=H4sIAM4GBmsC/yXMTQ6CMBBA4auQWTtJW5CKVzEsShlgDH/pCIEQ7
 k7V5bd47wChwCTwTA4ItLLwNEboWwK+c2NLyHU0GGVyrU2G+9Q6lJ4Hu6EMlUmtQu9qm94fhcq
 dhljOgRreftdX+bcs1Zv857uC87wAFoP3JHcAAAA=
X-Change-ID: 20261124-yoga-slim7x-smb2370-cad7358906a1
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 Marko Zidaric <darkobas@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1376; i=darkobas@gmail.com;
 h=from:subject:message-id; bh=PTLVAGVNPZeF9esS9Acb6R6hiwos8Jxkhf5ea1o2p+4=;
 b=owGbwMvMwMGYxdFjFCjQw8R4Wi2JIZuN7dWEV9GreKrVaxiz9ULVUrwudAWmh2761+bvKDn9b
 nrXpoRORn8WBkYOBksxRRa9w2tSrfhZA5uuRUyCGcTKBDJFWqSBAQhYGPhyE/NKjXSM9Ey1DfUM
 gQwdIwYuTgGY6mOq7H/4HvyNtTpgd3hvPrNz5d9HHku2sgm1vdv2Tz7BRTmH8azTl3nz7vno9K9
 UfDf/uCbfk6+Bk/udN/zRXCzF6ndL+kW4idlh97KDuvNkandl9BYYepXuc63Pn7n402d1S0k3Bp
 GvcaLFNxed9/3FvzqwWXLBpxdla4/0Xig88PjJwqmpbh4doqUHVla9M0tV2TDVfmeG5YOFCUoTJ
 Z6fnjLjxo70BLkDmnpJZqFZW/IX9wpc1VVQW3zEPEtI4iHvbZvyOWq6rn0XQwWkr2yUS7SSNRYO
 KVXVKgjY9m6y+eMvpZ73N3xTemDyYIbHWknFJGP+QHun44muhecmHWk+uXm1DKOvx4vc0GdiVx4
 L+gAA
X-Developer-Key: i=darkobas@gmail.com; a=openpgp;
 fpr=2EC3AC653A0F055182D658926A088C3251108C02
X-Endpoint-Received: by B4 Relay for darkobas@gmail.com/default with auth_id=1633
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The eUSB2 repeater of the third Type-C port sits on SMB2370_2, which is
disabled by default. The board file only set status on the repeater
child node, so usb_2 never probes.

Enable the PMIC node instead.

Fixes: a741ecde8949 ("arm64: dts: qcom: glymur: Add Lenovo Yoga Slim 7x Gen11")
Signed-off-by: Marko Zidaric <darkobas@gmail.com>
---
Tested on a Yoga Slim 7x Gen11 (83QR) on 7.4-rc3 only, by applying the
equivalent change to the DTB; the affected lines are unchanged in
current mainline.
---
 arch/arm64/boot/dts/qcom/glymur-lenovo-yoga-slim7x.dts | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/arch/arm64/boot/dts/qcom/glymur-lenovo-yoga-slim7x.dts b/arch/arm64/boot/dts/qcom/glymur-lenovo-yoga-slim7x.dts
index 769f195c9..c6012e162 100644
--- a/arch/arm64/boot/dts/qcom/glymur-lenovo-yoga-slim7x.dts
+++ b/arch/arm64/boot/dts/qcom/glymur-lenovo-yoga-slim7x.dts
@@ -870,11 +870,13 @@ &smb2370_k_e2_eusb2_repeater {
 	vdd3-supply = <&vreg_l7b_e0>;
 };
 
+&smb2370_l_e2 {
+	status = "okay";
+};
+
 &smb2370_l_e2_eusb2_repeater {
 	vdd18-supply = <&vreg_l15b_e0>;
 	vdd3-supply = <&vreg_l7b_e0>;
-
-	status = "okay";
 };
 
 &swr0 {

---
base-commit: 8d7fe9885c62fc9a95bf55d9db244d9672a8aadc
change-id: 20261124-yoga-slim7x-smb2370-cad7358906a1

Best regards,
--  
Marko Zidaric <darkobas@gmail.com>

