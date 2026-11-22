From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:12:49 +0000
Subject: [PATCH] ARM: dts: qcom: msm8974-hammerhead: Link the fuel gauge to
 its charger
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-hammerhead-gauge-supply-v1-1-7ea708ee19a7@enser.io>
X-B4-Tracking: v=1; b=H4sIANB5AmsC/yXMQQ7CIBCF4as0s3YUsKmJVzFdDHQoGIsEpNE0v
 bugy+/l5d8gc/Kc4dptkHj12T9DhTx0YByFmdFP1aCEGqRUCnWPjpaFk2OacKZSL7nE+PjgYIS
 xSp6JhYUaiImtf//it/HvXPSdzasV20NTZtSJgnFtajytl2OPySjY9y/8cnaJngAAAA==
X-Change-ID: 20261122-b4-hammerhead-gauge-supply-6c0cf213ae0f
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324369; l=1672;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=G+WXz4mrHdbXmDyYNov98eadKi60GGqvVCOY3Vy/RcE=;
 b=wz3O/8b3kvgzjOkt2rAvMO4D5fgT3zG70BXduDP1yX/lGmhhEPIa6mWv5IdRB28D1cDC5th0e
 TtOz6hy1oWJBjK+i1Gg4oazx38cIGb8cmAquGH9qIgh7KQZbyQoHjrj
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The max17048 fuel gauge takes its STATUS from the power supply that
feeds it, but its node does not say which one that is, so the gauge
reports Unknown however the battery is being charged. Point it at the
bq24192 charger with power-supplies, as the max17040 binding's own
example does.

The driver only reads the property since "power: supply: max17040: pass
the device fwnode to the power supply core", now in the power-supply
tree. Tested on an LG Nexus 5 with that same one-line driver change:
with a charger attached the battery's status reads Charging, as the
charger's does. Without the driver change this patch is harmless and
has no effect.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
 arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts b/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts
index e34d7b864e..48be1f9835 100644
--- a/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts
+++ b/arch/arm/boot/dts/qcom/qcom-msm8974-lge-nexus5-hammerhead.dts
@@ -120,6 +120,7 @@ charger: bq24192@6b {
 	fuelgauge: max17048@36 {
 		compatible = "maxim,max17048";
 		reg = <0x36>;
+		power-supplies = <&charger>;
 
 		maxim,double-soc;
 		maxim,rcomp = /bits/ 8 <0x4d>;

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-hammerhead-gauge-supply-6c0cf213ae0f

Best regards,
--  
EMCP333 <emcp@enser.io>

