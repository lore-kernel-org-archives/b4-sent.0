From: Xilin Wu <wuxilin123@gmail.com>
Subject: [PATCH RESEND 0/2] Introduce ASUS Vivobook S 15
Date: Fri, 28 Jun 2024 19:49:33 +0800
Message-Id: <20240628-asus-vivobook-s15-v1-0-92cb39f3f166@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAE2jfmYC/32NOw7CMBBErxJtzaKsycdQUZCWAkqUwgkmWUFi5
 AULFOXuWDkA5ZvRvJlArGcrsEsm8DawsBsj0CqBtjdjZ5GvkUGlKksLpdHIWzBwcI1zdxTKsVQ
 m25a62FChIe6e3t74szgvcKrO1fEAdcx7lpfz3+Uq0NL+sQbCFJUhm+UlNdo0+24w/Fi3boB6n
 ucfFpZhJboAAAA=
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konrad.dybcio@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Abel Vesa <abel.vesa@linaro.org>, 
 Johan Hovold <johan+linaro@kernel.org>, Xilin Wu <wuxilin123@gmail.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1719575382; l=2004;
 i=wuxilin123@gmail.com; s=20240424; h=from:subject:message-id;
 bh=0I+r8Bzyzaqu9bFb0Ty+lOwGyBNGIZfkjaSm1li3Tqw=;
 b=dMP0dS6tpEfExHXKCM/hZ1/UTrzeOPPfyohGLUbAmAqKk71rHky9+KiO1IJlmHmD7oLBvWemF
 igusOgcO45XAcjtCaktvIC0gDoiW39l5ZF+R5oJYw1V0p0v6ZqGFdMb
X-Developer-Key: i=wuxilin123@gmail.com; a=ed25519;
 pk=vPnxeJnlD/PfEbyQPZzaay5ezxI/lMrke7qXy31lSM8=
X-Endpoint-Received: by B4 Relay for wuxilin123@gmail.com/20240424 with auth_id=157
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

ASUS Vivobook S 15 is a laptop based on the Qualcomm Snapdragon X Elite
SoC (X1E78100). This series adds initial support for the device.

Currently working features:

- CPU frequency scaling up to 3.4GHz
- NVMe storage on PCIe 6a (capable of Gen4x4, currently limited to Gen4x2)
- Keyboard and touchpad
- WCN7850 Wi-Fi
- Two Type-C ports on the left side
- internal eDP display
- ADSP and CDSP remoteprocs

Some features which can get working with out of tree patches:

- GPU [1]
- Bluetooth [2]

Notably not working features:

- Battery monitoring via battmgr
- Orientation switching and altmode on the Type-C ports (USB4 retimer driver needed?)
- Two USB Type-A ports on the right side (dwc3 multiport controller)
- Front camera
- SD card slot
- HDMI connector (using a Parade PS186 DP 1.4 to HDMI 2.0 converter) 
- USB4 and the retimer (Parade PS8830?)
- Anything using the EC

Dump of the ACPI tables could be found here: [3]

[1] https://lore.kernel.org/all/20240623110753.141400-1-quic_akhilpo@quicinc.com/
[2] https://git.codelinaro.org/abel.vesa/linux/-/commits/topic/b4/x1e80100-bt
[3] https://github.com/aarch64-laptops/build/pull/103

Signed-off-by: Xilin Wu <wuxilin123@gmail.com>
---
Changes in v2:
- EDITME: describe what is new in this series revision.
- EDITME: use bulletpoints and terse descriptions.
- Link to v1: https://lore.kernel.org/r/20240628-asus-vivobook-s15-v1-0-2a1e4571b8ab@gmail.com

---
Xilin Wu (2):
      dt-bindings: arm: qcom: Add ASUS Vivobook S 15
      arm64: dts: qcom: Add device tree for ASUS Vivobook S 15

 Documentation/devicetree/bindings/arm/qcom.yaml    |   1 +
 arch/arm64/boot/dts/qcom/Makefile                  |   1 +
 .../boot/dts/qcom/x1e80100-asus-vivobook-s15.dts   | 613 +++++++++++++++++++++
 3 files changed, 615 insertions(+)
---
base-commit: 642a16ca7994a50d7de85715996a8ce171a5bdfb
change-id: 20240628-asus-vivobook-s15-72a497863168

Best regards,
-- 
Xilin Wu <wuxilin123@gmail.com>

