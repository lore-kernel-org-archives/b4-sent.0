From: Antony Kurniawan Soemardi <linux@smankusors.com>
Subject: [PATCH v4 0/7] ARM: qcom: msm8960: enable WCNSS (Bluetooth &
 Wi-Fi)
Date: Mon, 03 Aug 2026 02:03:44 +0700
Message-Id: <20260803-msm8960-wifi-v4-0-5ffa27aea39d@smankusors.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJCUb2oC/23QQQ6CMBAF0KuYrq1pSxnAlfcwLko7SGMAbQE1h
 Ltb0IQoLv9P5iV/BuLRWfRkvxmIw95629QhyO2G6FLVZ6TWhEwEEzEXAmjlqzQDRu+2sDRH1CY
 DDSCBhJOrw8I+Zu54Crm0vm3cc9Z7PrUTBExy+Q31nDLKWFIYlRngkTz4StWXzjfO73RTkUnrx
 SLEK0EEIdG5Qhkblcf4V4gWARj/EaIgFKhB6dTkiomVML4nOrx14VHtZ+c4vgDFduy5RgEAAA=
 =
X-Change-ID: 20251226-msm8960-wifi-beecd96c6646
To: Lee Jones <lee@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: phone-devel@vger.kernel.org, Rudraksha Gupta <guptarud@gmail.com>, 
 mfd@lists.linux.dev, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785697465; l=4453;
 i=linux@smankusors.com; s=20250609; h=from:subject:message-id;
 bh=PjVGgn8li1Fs4sPuetN9ryL0ip7HBh+kudxrBYMP6Zw=;
 b=GcXlyAAdli8arEo09cvF704gi02iE6pE3+Egx6gF52aOKsEs9EhYXg06KouYbHeVv9q5kVD+P
 +igje0v55WeD1IKfRI11Gu1lPd0heO80S/Bnv/bxaP6sh+0RoSfNwAf
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
- Add shared memory and hardware lock for inter-processor communication
- Add SCM node for secure channel manager interaction
- Add required QDSS clock resource for msm8960 RPM clock controller
- Add bindings for SPS interrupt controller and RPM clocks

This series supersedes the earlier dt-bindings-only submission [1] and
includes the corresponding driver and DT integration changes.

This series also fixes the dtbs_check warnings in msm8960.dtsi
introduced by:
  [2] "dt-bindings: usb: ci-hdrc-usb2: allow up to 3 clocks for
  qcom,ci-hdrc"

Tested on:
- Sony Xperia SP
- Samsung Galaxy Express (SGH-I437) - requires additional work for
  firmware loading (separate series pending)

Known limitations (not addressed in this series):
The wcn36xx driver appears to misclassify 2.4 GHz networks as 5 GHz
during hardware scanning, preventing association with 2.4 GHz networks.
This issue has also been observed on MSM8916 and MSM8953 platforms
using WCN3620 [3][4].

[1] https://lore.kernel.org/all/20260218-msm8960-sps-rpm-bindings-v1-0-bbc11c0d4f24@smankusors.com/
[2] https://lore.kernel.org/all/20260516-qcom-ci-hdrc-clock-fix-v2-1-aaec8d33d0aa@smankusors.com/
[3] https://github.com/msm8916-mainline/linux/commit/cc4abc694fcf2c942410136bc58a61e79bf21e83
[4] https://github.com/msm8953-mainline/linux/commit/779c9627ec0b971bf466588e64fe530cf78a414d

Signed-off-by: Antony Kurniawan Soemardi <linux@smankusors.com>
---
Changes in v4:
- Dropped the qcom,rpmcc-msm8960 patches, as msm8960.dtsi now uses
  qcom,rpmcc-apq8064 instead.
- Dropped the qcom_rpm MFD patch, as it has been merged upstream.
  (Commit 6b6e7e965a11f761a3b614f5ff3fa8d1d9c86b1e mfd: qcom_rpm: Add msm8960 QDSS clock resource)
- Swapped the iface and core USB clocks in the msm8960.dtsi
- Link to v3: https://patch.msgid.link/20260601-msm8960-wifi-v3-0-fec6ac8dba02@smankusors.com

Changes in v3:
- Dropped unnecessary pxo and cxo clock validations for
  qcom,rpmcc-msm8960
- Dropped unnecessary example for rpmcc bindings
- Reorder USB clock entries to match the updated ci-hdrc binding, using
  iface, core, fs order.
- Link to v2: https://patch.msgid.link/20260514-msm8960-wifi-v2-0-7cbae45dab5e@smankusors.com

Changes in v2:
- Updated cover letter about the previous dt-bindings only submission
  and the dependency on the USB controller clock fix series
- Drop the apq8064 reference from the commit message for adding msm8960
  QDSS clock resource
- Add fallback compatible "qcom,rpmcc-apq8064" in the rpmcc node
- Updated qcom,rpmcc dt-bindings to allow for fallback compatible
- Put clocks, clock-names, reg, reg-names, interrupt-names, &
  smem-states entries one per line in the rpmcc, riva, and wifi nodes
- Move riva pinctrl assignments to SoC DTSI
- Renamed hwmutex to hwlock for consistency with the dt-bindings
- Link to v1: https://patch.msgid.link/20260414-msm8960-wifi-v1-0-007fda9d6134@smankusors.com
- Note: an incomplete v1 also exists at https://lore.kernel.org/all/20260414-msm8960-wifi-v1-0-01c081e54610@smankusors.com/
  due to SMTP rate limit. Please ignore that thread.

---
Antony Kurniawan Soemardi (7):
      dt-bindings: mfd: syscon: add qcom,msm8960-sps-sic
      ARM: dts: qcom: msm8960: add RPM clock controller and fix USB clocks
      ARM: dts: qcom: msm8960: add SCM
      ARM: dts: qcom: msm8960: add SMEM & hwlock
      ARM: dts: qcom: msm8960: add SMSM & SPS
      ARM: dts: qcom: msm8960: add Riva
      ARM: dts: qcom: msm8960: huashan: enable Wi-Fi and Bluetooth

 Documentation/devicetree/bindings/mfd/syscon.yaml  |   2 +
 .../boot/dts/qcom/qcom-msm8960-sony-huashan.dts    |  15 ++
 arch/arm/boot/dts/qcom/qcom-msm8960.dtsi           | 169 ++++++++++++++++++++-
 3 files changed, 184 insertions(+), 2 deletions(-)
---
base-commit: 2d2338c93da79b3bfe4b6099a931d9468d539952
change-id: 20251226-msm8960-wifi-beecd96c6646

Best regards,
--  
Antony Kurniawan Soemardi <linux@smankusors.com>

