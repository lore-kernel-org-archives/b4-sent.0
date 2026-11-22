From: EMCP333 <emcp@enser.io>
Date: Sun, 22 Nov 2026 05:13:43 +0000
Subject: [PATCH] arm64: dts: qcom: sdm845-oneplus-fajita: Add the battery's
 design energy
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-b4-fajita-battery-energy-v1-1-ce6f0d69947e@enser.io>
X-B4-Tracking: v=1; b=H4sIAAZ6AmsC/yXMwQ6CMBAE0F8he3aVNi1Gf4V4aMsCy6GabSUSw
 r/b6vFNZmaHRMKU4N7sILRy4mcsUKcGwuziRMhDMehWd0ppjd7g6BbODr3LmWRDiiTThibojgZ
 LN9taKPOX0Mif33X/+Du9/UIh17/a8C4RenExzDWqvKzXs0EJGo7jC9YC32ycAAAA
X-Change-ID: 20261122-b4-fajita-battery-energy-4c26ed5e9505
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Abel Vesa <abelvesa@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Rinat Muhamedgaliev <rinat.muhamedgaliev@gmail.com>, 
 Hex Lindqvist <hex@freenixos.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324423; l=2515;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=deghCqiCJANOaAyPTby9MMGyOUPEwGJ7upq4xsrZF8k=;
 b=MeBE0hwlq1FbKxadWmdNqFHN+TiS9VoPkPHqQK0v2FtkTHR0mpDeSHXr4LRBGn9FA2RmvbnP2
 sN3XqwSFEZyAhEobm5a+B1u++GX6KT7e4boPANQOKiM58gCFPZIvSsR
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The fajita battery node has charge-full-design-microamp-hours but no
energy-full-design-microwatt-hours. bq27xxx writes the design capacity
and design energy into the bq27411's data memory only when both are
set, so neither is written, and the driver warns at every probe:

  bq27xxx-battery 10-0055: missing battery:energy-full-design-microwatt-hours

The power supply core also leaves energy_full_design out of sysfs.

Add the design energy. The BLP685 pack is rated 3.85 V, 3700 mAh and
14.24 Wh typical (3610 mAh and 13.89 Wh minimum); 3700 mAh is the
capacity the node already uses, and 3700 mAh x 3.85 V = 14245000 uWh.

Some replacement packs carry a bq27541, which has no data memory
update; on those units the property only adds energy_full_design.

Tested on a OnePlus 6T whose gauge reports DeviceType 0x0421
(bq27411), with this patch on a 6.18-based kernel. The first boot logs
"update design-energy to 14245" and no longer warns, and
energy_full_design reads 14245000. After a power-off, the next boot
logs "design-energy has 14245". The boot that writes the data memory
also logs "cfgupdate 0, retries 17": leaving config update took 17
retries, and the driver warns after 3. The write itself completed, as
the next boot shows.

The code and this changelog were prepared with the help of an AI coding
assistant. The submitter has reviewed both and takes responsibility for
them.

Signed-off-by: EMCP333 <emcp@enser.io>
---
Also ran on v7.4-rc3 on the same phone, as this exact commit: the gauge
reports DeviceType 0x0421, energy_full_design reads 14245000, and the
boot logs "design-energy has 14245" (the data memory was written by an
earlier boot).
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index e9d1a1c6ac..dc3a7a8f97 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -16,6 +16,7 @@ battery: battery {
 		compatible = "simple-battery";
 
 		charge-full-design-microamp-hours = <3700000>;
+		energy-full-design-microwatt-hours = <14245000>;
 		voltage-min-design-microvolt = <3400000>;
 		voltage-max-design-microvolt = <4400000>;
 

---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-fajita-battery-energy-4c26ed5e9505

Best regards,
--  
EMCP333 <emcp@enser.io>

