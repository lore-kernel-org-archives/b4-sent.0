From: EMCP333 <emcp@enser.io>
Subject: [PATCH 0/3] Touchscreen wakeup for the OnePlus 6 and 6T
Date: Sun, 22 Nov 2026 05:13:49 +0000
Message-Id: <20261122-b4-rmi4-wakeup-v1-0-1b662be4a9d6@enser.io>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA16AmsC/yXM0Q6CMAyF4Vchvbbq5hTwVYwX3ahSjZOsgiaEd
 3fTy6/p+WdQTsIKx2qGxJOoPGOGWVUQeopXRumywW7twRhr0TtMD3H4pjuPA+5b17impl3LHeT
 RkPgin1/wdP5bR3/j8CqV8uFJGX2iGPpyKtxM9Tpng4Vl+QInVbR7kgAAAA==
X-Change-ID: 20261122-b4-rmi4-wakeup-5948487a39ed
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>, 
 Abel Vesa <abelvesa@kernel.org>, Casey Connolly <casey.connolly@linaro.org>, 
 linux-input@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 EMCP333 <emcp@enser.io>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795324430; l=2234;
 i=emcp@enser.io; s=ultron; h=from:subject:message-id;
 bh=QsipX2VlKzNSrE69Li9weyplTtRqzi4er6aXQmYWKZU=;
 b=Ujgb/6+o4SSZEZGHqa6k3zVuHNJ3GGH5slwBQhXUXAED0jiFfNVOj9jWe9PMmkOvOat5tntXw
 RUsFCVng9YYBOz2bw0tTuDNeyk/bFb2F4BoTXQs17VohXNLhIqsxsOK
X-Developer-Key: i=emcp@enser.io; a=ed25519;
 pk=5sG48Lul+Vn7OzXu3VZrCWk5uvEFPYMXYnAV0TZR/tY=
X-Endpoint-Received: by B4 Relay for emcp@enser.io/ultron with auth_id=1598
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Synaptics touchscreen on the OnePlus 6 and 6T is meant to wake the
SoC from s2idle. The I2C core and the rmi4 driver already handle
"wakeup-source", but rmi_i2c cuts the controller's supplies in system
suspend right after it arms the wake interrupt. Unpowered, the
controller cannot report a touch, and on these phones cutting the
supplies also raises the attention interrupt, which ends every s2idle
within a few seconds.

Patch 1 lets the rmi4 binding accept "wakeup-source". Patch 2 keeps an
rmi4 I2C device that may wake the system powered in system suspend, as
edt-ft5x06 does. Patch 3 sets the property in
sdm845-oneplus-common.dtsi.

Patches 1 and 2 are for the input tree and patch 3 for the Qualcomm
tree. Patch 3 needs patch 1 for dtbs_check, and should not land before
patch 2: without it, every s2idle on these phones ends at once.

Tested on a OnePlus 6T on v7.4-rc3 with all three patches, rmi_core and
rmi_i2c built as modules from patch 2's commit. With nobody touching the
phone, "rtcwake -m freeze -s 30" slept the full 30 seconds with no
attention interrupt (2 of 2); without patch 2 it came back after 3 to 4
seconds, one attention interrupt each time (3 of 3). A double-tap on the
dark phone woke it from "rtcwake -m freeze -s 120" after 3 and 7
seconds, one attention interrupt burst each. With wakeup disabled the
supplies are cut as before and it slept the full 30 seconds (2 of 2).

On v7.4-rc2, dt_binding_check is clean, dtbs_check reports nothing new
for fajita or enchilada, and rmi_i2c.c builds cleanly with W=1.

---
EMCP333 (3):
      dt-bindings: input: syna,rmi4: Document wakeup-source
      Input: synaptics-rmi4 - keep an I2C device that may wake the system powered
      arm64: dts: qcom: sdm845-oneplus: Mark the touchscreen as a wakeup source

 .../devicetree/bindings/input/syna,rmi4.yaml       |  2 ++
 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi |  1 +
 drivers/input/rmi4/rmi_i2c.c                       | 22 +++++++++++++++-------
 3 files changed, 18 insertions(+), 7 deletions(-)
---
base-commit: 7475ea8b58616b33c04afb976cf0fbaad9dd63fb
change-id: 20261122-b4-rmi4-wakeup-5948487a39ed

Best regards,
--  
EMCP333 <emcp@enser.io>

