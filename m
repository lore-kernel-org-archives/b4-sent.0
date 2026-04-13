From: Antony Kurniawan Soemardi <linux@smankusors.com>
Subject: [PATCH 00/10] ARM: qcom: msm8960: enable WCNSS (Bluetooth & Wi-Fi)
Date: Tue, 14 Apr 2026 01:55:27 +0700
Message-Id: <20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB883WkC/x3MQQ5AQAxA0atI15rQ0OAqYsEouhhkmiCRubuJ5
 Vv8/4JJUDHosheCXGp67AllnoHbxn0V1DkZqKC6JGL05puWC7x1UZxE3NyyY64YUnIGWfT5d/0
 Q4wdy1J4oXgAAAA==
X-Change-ID: 20251226-msm8960-wifi-beecd96c6646
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Lee Jones <lee@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-arm-msm@vger.kernel.org, 
 linux-clk@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Rudraksha Gupta <guptarud@gmail.com>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1776106820; l=2611;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=NYwF55QA6txdrIoAGxylJ/Rgbbu7ua+pdJtGzMjggQ4=;
 b=EEEnBqermgK5yZU8PP0youZRIua/s25daTd5ma8b7a1S2XEenHGNFhQbRsOWo0L3nXNT6qDKv
 xqpqURXV1/kBVw6c++UcPgP+60pJbZthSABVgD5SmpyT5OG9yyDjrrk
X-Developer-Key: i=linux@smankusors.com; a=ed25519;
 pk=65wTy06fJl2/h/EJwjr704YG+yjHFhZObJBWzzK+N00=
X-Endpoint-Received: by B4 Relay for linux@smankusors.com/20250609 with auth_id=733
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the WCNSS (Riva) subsystem on MSM8960-based devices to support
Bluetooth and Wi-Fi.

Add the required device tree nodes and resources, including memory
regions, clocks, interconnects, and communication interfaces used by
the WCNSS firmware and drivers.

Changes:
- Add Riva (WCNSS) nodes: firmware memory, WCN3660 iris radio,
  Bluetooth and Wi-Fi subdevices, and pinctrl states
- Add SMSM and SPS nodes for coordination with the WCNSS subsystem
- Add shared memory and hardware mutex for inter-processor communication
- Add SCM node for secure channel manager interaction
- Add RPM clock controller and required QDSS clock resource
- Add bindings for SPS interrupt controller and RPM clocks

Known limitations (not addressed in this series):
The wcn36xx driver appears to misclassify 2.4 GHz networks as 5 GHz
during hardware scanning, preventing association with 2.4 GHz networks.
This issue has also been observed on MSM8916 and MSM8953 platforms
using WCN3620 [1][2].

Tested on:
- Sony Xperia SP
- Samsung Galaxy Express (SGH-I437) - secure firmware loading not yet
  functional (separate series pending)

[1] https://github.com/msm8916-mainline/linux/commit/cc4abc694fcf2c942410136bc58a61e79bf21e83
[2] https://github.com/msm8953-mainline/linux/commit/779c9627ec0b971bf466588e64fe530cf78a414d

Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
Antony Kurniawan Soemardi (10):
      dt-bindings: clock: qcom,rpmcc: add msm8960 compatible
      dt-bindings: mfd: syscon: add qcom,msm8960-sps-sic
      mfd: qcom_rpm: add msm8960 QDSS clock resource
      clk: qcom: clk-rpm: add msm8960 compatible
      ARM: dts: qcom: msm8960: add RPM clock controller and fix USB clocks
      ARM: dts: qcom: msm8960: add SCM
      ARM: dts: qcom: msm8960: add SMEM & hwmutex
      ARM: dts: qcom: msm8960: add SMSM & SPS
      ARM: dts: qcom: msm8960: add Riva
      ARM: dts: qcom: msm8960: huashan: enable Wi-Fi and Bluetooth

 .../devicetree/bindings/clock/qcom,rpmcc.yaml      |   5 +-
 Documentation/devicetree/bindings/mfd/syscon.yaml  |   2 +
 .../boot/dts/qcom/qcom-msm8960-sony-huashan.dts    |  19 +++
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           | 157 ++++++++++++++++++++-
 drivers/clk/qcom/clk-rpm.c                         |   1 +
 drivers/mfd/qcom_rpm.c                             |   1 +
 6 files changed, 182 insertions(+), 3 deletions(-)
---
base-commit: 978e0d8216cae014f10326c9a257890cf98a6398
change-id: 20251226-msm8960-wifi-beecd96c6646

Best regards,
--  
Antony Kurniawan Soemardi <linux@smankusors.com>

