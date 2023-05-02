From: Gabriel Tremblay <tremblay.gabriel@gmail.com>
Date: Tue, 02 May 2023 14:31:14 -0400
Subject: [PATCH] Change the interrupt from level_low to edge_falling
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20230502-gtremblay-x13s-keyboard-v1-1-6bc3e59b0d39@gmail.com>
X-B4-Tracking: v=1; b=H4sIAPFWUWQC/zXNQQqDMBCF4avIrDs0ThSaXqV0MdExhraxTEpRx
 Ls3Cl3+PD7eClk0SoZrtYLKN+Y4pRL1qYJu5BQEY18ayJA1rSEMH5WXf/KCc20zPmTxE2uPdHH
 OtoMjEoKiPWdBr5y6cfe+OQf5031/qwxxPp5v9237AVB2ldOJAAAA
To: Bjorn Andersson <andersson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Gabriel Tremblay <tremblay.gabriel@gmail.com>
X-Mailer: b4 0.12.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1683052280; l=1193;
 i=tremblay.gabriel@gmail.com; s=20230502; h=from:subject:message-id;
 bh=nbP1Xx1KAt958LpS5KvFFCWaYnFLYSX2Yz32vSKwDHU=;
 b=faBX9jx+sw9zzbs1OOJBCsG/3856f4GkZfvQqQ38ycrkKmFhL/mIyyzW1Lp+daHZlpOK7/PJZ
 hxMDIG9RBBdCfD19KjPfkiBjUBQg0fEv9Dh0H/kTAUS83Kol88Ly/sL
X-Developer-Key: i=tremblay.gabriel@gmail.com; a=ed25519;
 pk=QBcAw+03yiRPOAXsWfAlyaNIhBRPIH3l8tURId7/7Nw=
X-Endpoint-Received: by B4 Relay for tremblay.gabriel@gmail.com/20230502 with auth_id=45
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>



---
Lenovo's x13s internal keyboard shows responsivity issues when fast
typing occurs. The problem is not replicated with external HID keyboard.

This fix tries to alleviate the problem but requires further testing
and commenting.

Signed-off-by: Gabriel Tremblay <tremblay.gabriel@gmail.com>
---
 arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
index bdcba719fc38..e8d7f02c9bf3 100644
--- a/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
+++ b/arch/arm64/boot/dts/qcom/sc8280xp-lenovo-thinkpad-x13s.dts
@@ -639,7 +639,7 @@ keyboard@68 {
 		reg = <0x68>;
 
 		hid-descr-addr = <0x1>;
-		interrupts-extended = <&tlmm 104 IRQ_TYPE_LEVEL_LOW>;
+		interrupts-extended = <&tlmm 104 IRQ_TYPE_EDGE_FALLING>;
 		vdd-supply = <&vreg_misc_3p3>;
 		vddl-supply = <&vreg_s10b>;
 

---
base-commit: 84e2893b4573da3bc0c9f24e2005442e420e3831
change-id: 20230502-gtremblay-x13s-keyboard-289935f922e2

Best regards,
-- 
Gabriel Tremblay <tremblay.gabriel@gmail.com>

