From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH v2 0/2] Add pinctrl support for MSM8952
Date: Thu, 20 Aug 2026 14:17:16 +0300
Message-Id: <20260820-msm8952-pinctrl-v2-0-bf2b8b7b379b@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNyw6DIBBFf8XMujQysYBd9T8aF/IoTqJowJA2h
 n8vdd/lOck994DkIrkE9+aA6DIlWkMFvDRgpjF4x8hWBmxRtIoLtqRF9TdkGwWzx5lpg9p2qut
 RcKirLboXvc/ic6g8UdrX+DkPMv/Z/63MWctGiRK1sciVfCwjhZkCBX9do4ehlPIFlZigaLMAA
 AA=
X-Change-ID: 20260816-msm8952-pinctrl-bc2bd4849261
To: Bjorn Andersson <andersson@kernel.org>, 
 Linus Walleij <linusw@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787224657; l=1347;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=RSjpaCF9fBktE/a6UFELoM+28IIroymgdClaLF3mN+o=;
 b=mGo5kBGOZpeO2539Z962drHBw9m2kPBd9Daziv7TutmH1bemMC+UmA42qnTKO/u5i0bzhzKPv
 gJJGR8V1r/JCa+4IxV8GlaYxgCX6UborLuP3Jr0LlI2spvs9IGcz4qf
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8952 has pinctrl system that is similar to MSM8917 pinctrl, but it
has some differences in some of the pins and their functions.
This driver was tested on General Mobile GM 5 Plus
(shamrock) using my own kernel fork [1].
I'm holding off on sending the GCC (Global Clock
Controller) driver and initial device tree until I've resolved some
outstanding bugs in the GCC driver.

[1] https://github.com/kadir1243/linux

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
Changes in v2:
- Reworded dt-bindings commit as Krzysztof suggested.
- Added depends and default to kconfig entry of pinctrl
- Link to v1: https://lore.kernel.org/r/20260816-msm8952-pinctrl-v1-0-a7272bcd2187@mainlining.org

---
Muzaffer Kadir (2):
      dt-bindings: pinctrl: qcom: Add MSM8952 pinctrl
      pinctrl: qcom: Add MSM8952 tlmm pinctrl driver

 .../bindings/pinctrl/qcom,msm8952-pinctrl.yaml     |  155 +++
 drivers/pinctrl/qcom/Kconfig.msm                   |    8 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-msm8952.c             | 1248 ++++++++++++++++++++
 4 files changed, 1412 insertions(+)
---
base-commit: db2ddb87143519e20a95aa36c60b36107b736a58
change-id: 20260816-msm8952-pinctrl-bc2bd4849261

Best regards,
-- 
Muzaffer Kadir <muzafferkadir@mainlining.org>

