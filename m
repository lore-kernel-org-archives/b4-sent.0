From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH v5 0/7] Add Initial Support For MSM8952, Add General Mobile
 Shamrock
Date: Sun, 11 Oct 2026 19:51:22 +0300
Message-Id: <20261011-msm8952-initial-support-v5-0-1857074992ec@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OwWrDMAwG4FcpPs9DVmIn3mnvMXpwbCUVNE6ws
 9BR8u5zyxiFNTv+4tcnXUWmxJTF2+EqEq2ceYol6JeD8CcXB5IcShYIaMCClWMeW6tRcuSF3Vn
 mz3me0iINONDWIylNomzPiXq+3OWPY8knzsuUvu6HVnWb/pgKd81VSZBATY26aTuN9fvoOJ5LL
 Q6vUxrEDV7xETP7GBassa0vPQyB1FOsesBQ7WNVwTpr+lD1hLbtnmL1L6YA/vmsLhj54L1y3iD
 4P9i2bd88SDqeqgEAAA==
X-Change-ID: 20260909-msm8952-initial-support-60a059c2e15e
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, Amit Kucheria <amitk@kernel.org>, 
 Thara Gopinath <thara.gopinath@gmail.com>, 
 "Rafael J. Wysocki" <rafael@kernel.org>, 
 Daniel Lezcano <daniel.lezcano@kernel.org>, Zhang Rui <rui.zhang@intel.com>, 
 Lukasz Luba <lukasz.luba@arm.com>, Bjorn Andersson <andersson@kernel.org>, 
 Abel Vesa <abelvesa@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: David Heidelberg <david@ixit.cz>, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 linux-pm@vger.kernel.org, linux-input@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791737529; l=3978;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=eeHEV2MkIi+U50B2kClrbSibq1hG+SpbenmXjJHpank=;
 b=ZsWlzngOwlroEc7ZpShouNNhxpcBcWzhwzhUxDLeErgfcl4r/guv6VNJ1w9jv3ekhoNnfK/4G
 uWcHV1XlXBwBPo4X3cC91BEAlZ1MkmYcS9NPPscbL5fodjXE+U/UjUz
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8952 is a SoC with 8 core cpu and Adreno 405 gpu.

Ported without uart connection. ramoops and usb
mainly used to debug.
USB is not enabled in this series because it
depends on the not yet upstreamed (and not developed by me)
pmi8950_smbcharger.

General Mobile shamrock display panel driver
is generated using MSM8916's mdss dsi panel
driver generator and tested with it. I didn't
include it.

Pinctrl driver was submitted and merged here:
https://lore.kernel.org/all/20260907-msm8952-pinctrl-v5-0-9a2d8d72ffdb@mainlining.org/

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
Changes in v5:
- Added opp table for spi and uart.
- Wired all i2c and spi power-domains
- Dropped default slope from thermal driver.
- Link to v4: https://patch.msgid.link/20261006-msm8952-initial-support-v4-0-ecdcc1ac620c@mainlining.org

Changes in v4:
- Dropped 1651200000 freq on cluster 1 because it depends on speedbin 3
  and speedbin is not included in this patch series
- Dropped applied patches
- Changed mdss_dsi0 power-domain to MDSS_GDSC
- Reformatted SoC dtsi file
- Added the remaining reserved-memory entries for not added parts
- Rename adsp_mem to adsp_fw_mem
- Drop the "ts-" prefix of touchscreen pinctrl in device dts.
- Link to v3: https://patch.msgid.link/20260921-msm8952-initial-support-v3-0-b96fd3fe298b@mainlining.org

Changes in v3:
- Improved GCC driver, also rewrote resets part
- Rewrote the dt-binding side of gcc
- Reformatted Device tree files with dt-check-style tool
- Added reset to sdhci1 and sdhci2
- Added cx regulator to gcc
- Added gcc commit messages that it is a derived driver
- Dropped adsp_mem, renamed lpass_mem to adsp_mem
- Changed tusb320 interrupt from rising to falling as downstream uses
- Link to v2: https://patch.msgid.link/20260916-msm8952-initial-support-v2-0-798c2602dde1@mainlining.org

Changes in v2:
- Changed device dts file as David's and Konrad's suggestions
- Removed accidental duplicated clock assigments and fixed wrong gcc gp1,gp2
  and gp3 parent_maps
- Updated commit messages to make it wrapped at 72 character.
- Fixed spi1 tlmm node naming
- Added remaining spi and i2c nodes
- Wired up mpm
- Add mmio-sram to rpm_msg_ram
- Reformatted msm8952.dtsi
- Removed rpmcc-msm8952 driver entry and replaced it with rpmcc-msm8976
- Merged sdhci tlmm pins to single nodes, now it is similar to existing SoCs
- Rebased to latest linux-next, now storage works
- Removed polling-delay properties from tsens
- Link to v1: https://lore.kernel.org/r/20260912-msm8952-initial-support-v1-0-0e742578b524@mainlining.org

---
Muzaffer Kadir (7):
      dt-bindings: nvmem: Add compatible for MSM8952
      dt-bindings: iommu: qcom,iommu: Add MSM8952 IOMMU to SMMUv2 compatibles
      dt-bindings: thermal: tsens: Add MSM8952
      thermal: qcom: tsens: Add support for MSM8952 tsens
      arm64: dts: qcom: Add initial support for MSM8952
      dt-bindings: input: touchscreen: goodix: Add binding for GT970
      arm64: dts: qcom: generalmobile-shamrock: new device

 .../bindings/input/touchscreen/goodix.yaml         |   35 +-
 .../devicetree/bindings/iommu/qcom,iommu.yaml      |    1 +
 .../devicetree/bindings/nvmem/qcom,qfprom.yaml     |    1 +
 .../devicetree/bindings/thermal/qcom-tsens.yaml    |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../dts/qcom/msm8952-generalmobile-shamrock.dts    |  435 +++
 arch/arm64/boot/dts/qcom/msm8952.dtsi              | 2784 ++++++++++++++++++++
 drivers/thermal/qcom/tsens-v1.c                    |   41 +
 drivers/thermal/qcom/tsens.c                       |    3 +
 drivers/thermal/qcom/tsens.h                       |    2 +-
 10 files changed, 3288 insertions(+), 16 deletions(-)
---
base-commit: becb95e45ef0dda9ffb35156d909d3da7a2789c3
change-id: 20260909-msm8952-initial-support-60a059c2e15e

Best regards,
--  
Muzaffer Kadir <muzafferkadir@mainlining.org>

