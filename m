From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH v3 0/2] Add pinctrl support for MSM8952
Date: Fri, 04 Sep 2026 15:15:09 +0300
Message-Id: <20260904-msm8952-pinctrl-v3-0-110515fff513@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XNQQqDMBCF4atI1k1JRmtiV71H6cKJUQc0SiKhR
 bx7o6uCdPk/mG9WFqwnG9g9W5m3kQJNLkV+yZjpa9dZTk1qBgJKoWXJxzDq6gZ8JmcWP3A0gE2
 hiwpKydLV7G1L70N8vlL3FJbJf44HUe7rfytKLnitQAGaBqRWj7EmN5Aj110n37EdjPCDgDgjk
 BBsATUqzFWFJ2Tbti9zpKjZ+AAAAA==
X-Change-ID: 20260816-msm8952-pinctrl-bc2bd4849261
To: Bartosz Golaszewski <brgl@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, Linus Walleij <linusw@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, linux-gpio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788524120; l=1511;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=12BfSrTcPi4xiLBNgNrbzE4C1/0ne2TkNTelRRlK+Nk=;
 b=gsKkCZmEplMwyOZUY9hO8Di9Llmy5zgdfZBj0UJHiaIxlUdRcLwIDBchmxUk2Ang5y94+BQOF
 iOp6Jkjbs+lCFQ8jVf4MdHlLcb4DwOql3ASQNLD9bmUbLcANPVCViJI
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8952 has pinctrl system that is similar to MSM8917 pinctrl, but it
has some differences in some of the pins and their functions.
This driver tested on General Mobile GM 5 Plus.

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
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
 drivers/pinctrl/qcom/pinctrl-msm8952.c             | 1194 ++++++++++++++++++++
 4 files changed, 1349 insertions(+)
---
base-commit: 32b6ef9a5d0eca44f9cd91f52f4faa89f145a0de
change-id: 20260816-msm8952-pinctrl-bc2bd4849261

Best regards,
-- 
Muzaffer Kadir <muzafferkadir@mainlining.org>

