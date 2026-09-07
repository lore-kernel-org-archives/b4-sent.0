From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH v5 0/2] Add pinctrl support for MSM8952
Date: Mon, 07 Sep 2026 19:05:23 +0300
Message-Id: <20260907-msm8952-pinctrl-v5-0-9a2d8d72ffdb@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4XPwYrDIBCA4VcpnuvijBq1p75H2UNMNB1oTNESd
 gl59zW97EK69PgPzDfMwkrIFAo7HRaWw0yFplRDHw+su7ZpCJz62gwFNsJCw8cyWqeR3yl1j3z
 jvkPfK6scNsDq1j2HSF9P8fJZ+0rlMeXv54EZtun/1gxc8NagQd/1CNacx5bSjRKl4WPKA9vAG
 f8gKPYIVsRH9NYbL43zLxH5izih9oisCIDQoGOMGuRLRL1BVEUaA8ro0IN0+3fWdf0BR6gs1YI
 BAAA=
X-Change-ID: 20260816-msm8952-pinctrl-bc2bd4849261
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788797124; l=2000;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=w8EZ05k0q853OfA8iwP87wk48lOVG5pSeQC1y/3ymSg=;
 b=pA6RhdN/1ibvbeFEwNkdgITnMcWvxfF7Dp8JxNN0tH/UXSnBHDkzfYlSVPB7N86uv4p1bduMq
 63EpZ75pVhADjc58yTB1hOERpFWjP5pxBZXRtebFmk3RlYel1oKU79S
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8952 has pinctrl system that is similar to MSM8917 pinctrl, but it
has some differences in some of the pins and their functions.
This driver tested on General Mobile GM 5 Plus.

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
Changes in v5:
- Add mpm map as Konrad Dybcio provided.
- Change "GPL v2" to "GPL" as Konrad Dybcio suggested.
- Add missing pin mappings for qdss_tracedata_b and
  atest_combodac_to_gpio_native functions.
- Link to v4: https://lore.kernel.org/r/20260904-msm8952-pinctrl-v4-0-671475ed1397@mainlining.org

Changes in v4:
- Revert back accidentally changed dt-bindings gpio regex.
- Link to v3: https://lore.kernel.org/r/20260904-msm8952-pinctrl-v3-0-110515fff513@mainlining.org

Changes in v3:
- Added missing functions and removed unnecessary functions
  with Konrad Dybcio's suggestions.
- Because of the changes on functions, I changed dt-bindings too.
  Dropped Krzysztof's Reviewed-By attribute because of the changes.
- Rebased and Tested on linux-next, next-20260902 tag.
- Link to v2: https://lore.kernel.org/r/20260820-msm8952-pinctrl-v2-0-bf2b8b7b379b@mainlining.org

Changes in v2:
- Reworded dt-bindings commit as Krzysztof suggested.
- Added depends and default to kconfig entry of pinctrl
- Link to v1: https://lore.kernel.org/r/20260816-msm8952-pinctrl-v1-0-a7272bcd2187@mainlining.org

---
Muzaffer Kadir (2):
      dt-bindings: pinctrl: qcom: Add MSM8952 pinctrl
      pinctrl: qcom: Add MSM8952 tlmm pinctrl driver

 .../bindings/pinctrl/qcom,msm8952-pinctrl.yaml     |  146 +++
 drivers/pinctrl/qcom/Kconfig.msm                   |    8 +
 drivers/pinctrl/qcom/Makefile                      |    1 +
 drivers/pinctrl/qcom/pinctrl-msm8952.c             | 1257 ++++++++++++++++++++
 4 files changed, 1412 insertions(+)
---
base-commit: 32b6ef9a5d0eca44f9cd91f52f4faa89f145a0de
change-id: 20260816-msm8952-pinctrl-bc2bd4849261

Best regards,
-- 
Muzaffer Kadir <muzafferkadir@mainlining.org>

