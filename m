From: Ricky Cheung <rcheung844@gmail.com>
Subject: [PATCH 0/3] arm64: dts: qcom: msm8916-xiaoxun-jz0145-v33: Add
 initial device tree
Date: Tue, 14 Jan 2025 22:11:17 +0800
Message-Id: <20250114-xiaoxun-jz0145-v33-v1-0-dc51f7ce3bd8@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIVwhmcC/x3MMQqAMAxA0atIZgNJqw5eRRykRo1DlRalWLy7x
 fEN/2eIElQi9FWGILdGPXwB1xW4bfKroM7FYMi0xNxg0ulIl8f9IW5avK1FY2dH1LmFLUEJzyC
 Lpn86jO/7AaeUMlpkAAAA
X-Change-ID: 20250114-xiaoxun-jz0145-v33-23dc006cf130
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, Ricky Cheung <rcheung844@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1736863880; l=2342;
 i=rcheung844@gmail.com; s=20250114; h=from:subject:message-id;
 bh=wJsHWxYhcsyG5A7Fmu89Lm5IzY+TrzTNbM1pZ6xRyuE=;
 b=ZAXZ0/J6ksJVo7SKTvqRwfq1e9sErlRm7OX9qB4dMAKAmPD0E5Uc7ajZvbQ9PkPyX9ka/yHbv
 yt1YQ9/4mLACYvsHIOn/sqzdng3Inmggvl2U5jkRbNkwbW7AneC43bQ
X-Developer-Key: i=rcheung844@gmail.com; a=ed25519;
 pk=JjZsSnuDD1xuR4EXY4XGKELgToA++HxxheDlHU/41yI=
X-Endpoint-Received: by B4 Relay for rcheung844@gmail.com/20250114 with auth_id=323
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Good evening.

This patch adds support for the XiaoXun JZ0145 v33 4G LTE WiFi modem
based on the MSM8916 chipset by a new manufacturer / vendor for the
Linux Kernel called called XiaoXun BiCheng Technology. Below is some
information about these changes.

Addition of a new vendor prefix
----------

XiaoXun BiCheng Technology is not well known in that they don't seem
to have a presence in the Western world. I purchased my own modem
on TaoBao, which requires stores to registered as businesses, so
I believe it is justified to add it as a vendor prefix. Note that the
company appears to have shut down just this month.

Status of patch
----------

This device shares many similarities to pre-existing devices within
arch/arm64/boot/dts/msm8916-ufi.dtsi, so I am sure most features would
function with the correct firmware on this device.

However, due to the poor quality of these devices, my unit's EMMC has
failed and I cannot conduct further tests. Previous, the modem was
able to boot with devicetree of a UZ801, albeit with LED and Modem
issues, which is addressed in this patch.

I have sent the code for testing to some kind folks on the Internet with
good outcomes, so do consider this code as ready and functional.

This patch was also reviewed over at the msm8916-mainline organization
and deemed ready by the maintainer:

	https://github.com/msm8916-mainline/linux/pull/386

Note that this is my first patch to the LKML, so if there's something I
did wrong / the patch is missing, please point it out.

Best Regards,
Ricky Cheung
Tipz Team

Signed-off-by: Ricky Cheung <rcheung844@gmail.com>
---
Ricky Cheung (3):
      dt-bindings: vendor-prefixes: Add XiaoXun BiCheng Technology
      dt-bindings: arm: qcom: Add XiaoXun JZ0145 v33
      arm64: dts: qcom: msm8916-xiaoxun-jz0145-v33: Add initial device tree

 Documentation/devicetree/bindings/arm/qcom.yaml    |  1 +
 .../devicetree/bindings/vendor-prefixes.yaml       |  2 +
 arch/arm64/boot/dts/qcom/Makefile                  |  1 +
 .../boot/dts/qcom/msm8916-xiaoxun-jz0145-v33.dts   | 66 ++++++++++++++++++++++
 4 files changed, 70 insertions(+)
---
base-commit: d390303b28dabbb91b2d32016a4f72da478733b9
change-id: 20250114-xiaoxun-jz0145-v33-23dc006cf130

Best regards,
-- 
Ricky Cheung <rcheung844@gmail.com>

