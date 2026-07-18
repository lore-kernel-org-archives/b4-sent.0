From: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
Subject: [PATCH 0/5] usb: typec: ps883x: fixes for older Thunderbolt 4 /
 USB4 docks
Date: Sat, 18 Jul 2026 19:06:28 +0200
Message-Id: <20260718-ps883x-disable-usb4-v1-0-cec86d0b909e@oldschoolsolutions.biz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MSwqAMAwA0atI1gZav9WriItGowZEpUERxLtbX
 L7FzAPKQVihTR4IfInKvkXYNIFh8dvMKGM0ZCarTG0dHupcfuMo6mllPJUKtA2ZabA5lZ4glkf
 gSe7/2vXv+wFCb18kZQAAAA==
X-Change-ID: 20260718-ps883x-disable-usb4-19b0fc13b5ab
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 stable@vger.kernel.org, "Dr. David Alan Gilbert" <dave@treblig.org>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784394390; l=3110;
 i=jens.glathe@oldschoolsolutions.biz; s=20240919; h=from:subject:message-id;
 bh=YVzVTS3yfTz3Fpn4bxNP94OBR+Wp6n8cJXaURHReZ6U=;
 b=DZWzcN6ExfomMn/qKUwIcdGwtfI7YlcHPZ+0pbphXAgeO88tq3W1ZInBAdA4WjN4ILSaVtQ/5
 ltNIjewtXObDIcYbMuWPQlarhGXAhQ4NDQXDShX0JIQ58K2s2dEGz6F
X-Developer-Key: i=jens.glathe@oldschoolsolutions.biz; a=ed25519;
 pk=JcRJqJc/y8LsxOlPakALD3juGfOKmFBWtO+GfELMJVg=
X-Endpoint-Received: by B4 Relay for jens.glathe@oldschoolsolutions.biz/20240919 with auth_id=216
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

On Qualcomm X1E80100 platforms (e.g. Lenovo ThinkPad T14s Gen 6)
using the Parade PS883x retimer, connecting USB4-capable docks such
as the Lenovo 40B0 via a regular Type-C cable (which forces the dock
into Type-C fallback mode) often results in working USB but no
DisplayPort output.

This series addresses the issue with two main changes:

- Add a new optional DT property "parade,disable-usb4". When present,
  the PS883x driver rejects USB4 mode (-EOPNOTSUPP). This forces the
  Type-C stack to fall back to USB3 + DP Alt Mode, which works
  reliably with the 40B0.

- Refactor DP altmode handling to also support the legacy
  TYPEC_DP_STATE_F request (deprecated since DP Alt Mode 1.0b) sent by
  the 40B0 and other docks (e.g. SSK SC220).

- Add a short delay after writing configuration registers, which
  improves hotplug reliability.

This is a temporary workaround until full USB4 DP tunneling support is
available in the X1E USB4 controller and qmp-combo PHY stack.

Note: The DT patch adds the new property to all currently upstream
boards using the PS883x retimer (15 files). Happy to split it on v2
if requested.

As an additional observation, the same dock with type-c cable works well
on Thinkpad X13s, Thinkbook 16 G7 QOY, Ideapad 5 14Q8X9, but doesn't need
the ps883x changes (naturally). 

Signed-off-by: Jens Glathe <jens.glathe@oldschoolsolutions.biz>
---
Jens Glathe (5):
      dt-bindings: usb: parade,ps8830: Add parade,disable-usb4 property
      usb: typec: ps883x: Return -EOPNOTSUPP for USB4 when parade,disable-usb4 is set
      usb: typec: mux: ps883x: refactor DP altmode handling and support TYPEC_DP_STATE_F
      usb: typec: mux: ps883x: add a delay after writing config regs
      arm64: dts: qcom: x1: disable ps883x USB4 capability

 .../devicetree/bindings/usb/parade,ps8830.yaml     |  6 +++
 arch/arm64/boot/dts/qcom/hamoa-iot-evk.dts         |  4 ++
 .../qcom/hamoa-lenovo-ideacentre-mini-01q8x10.dts  |  2 +
 arch/arm64/boot/dts/qcom/purwa-iot-evk.dts         |  6 +++
 arch/arm64/boot/dts/qcom/x1-asus-vivobook-s15.dtsi |  4 ++
 arch/arm64/boot/dts/qcom/x1-asus-zenbook-a14.dtsi  |  4 ++
 arch/arm64/boot/dts/qcom/x1-crd.dtsi               |  6 +++
 arch/arm64/boot/dts/qcom/x1-dell-thena.dtsi        |  4 ++
 arch/arm64/boot/dts/qcom/x1-hp-omnibook-x14.dtsi   |  2 +
 arch/arm64/boot/dts/qcom/x1-microsoft-denali.dtsi  |  4 ++
 arch/arm64/boot/dts/qcom/x1e001de-devkit.dts       |  6 +++
 .../dts/qcom/x1e78100-lenovo-thinkpad-t14s.dtsi    |  4 ++
 .../boot/dts/qcom/x1e80100-dell-xps13-9345.dts     |  4 ++
 .../boot/dts/qcom/x1e80100-lenovo-yoga-slim7x.dts  |  6 +++
 .../dts/qcom/x1e80100-medion-sprchrgd-14-s1.dts    |  2 +
 .../boot/dts/qcom/x1e80100-microsoft-romulus.dtsi  |  4 ++
 drivers/usb/typec/mux/ps883x.c                     | 47 +++++++++++++++-------
 17 files changed, 100 insertions(+), 15 deletions(-)
---
base-commit: 0718283ab28bc3907e10b61a6b4be6fefa1cbb2f
change-id: 20260718-ps883x-disable-usb4-19b0fc13b5ab

Best regards,
-- 
Jens Glathe <jens.glathe@oldschoolsolutions.biz>

