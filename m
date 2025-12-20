From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Subject: [PATCH v5 0/7] Microsoft Surface Pro 11 support
Date: Sat, 20 Dec 2025 01:21:57 +0100
Message-Id: <20251220-surface-sp11-for-next-v5-0-16065bef8ef3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACXsRWkC/43NQQ6DIBCF4asY1p1GQMR05T2aLgAHJaliwBIb4
 92Lrrprl/9L5puNRAwOI7kVGwmYXHR+yiEuBTGDmnoE1+UmrGSCMtpAfAWrDEKcKQXrA0y4LlC
 zGjmTVmrOSb6dA1q3nu79kXtwcfHhfb5J/Fh/iYlDCY0UyhqpO65l24/KPa/Gj+QQU/WXUmVFa
 mMbbqgoK/Wt7Pv+ASKZ4nwAAQAA
X-Change-ID: 20251218-surface-sp11-for-next-626e327f7b33
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Lorenzo Bianconi <lorenzo@kernel.org>, 
 Maximilian Luz <luzmaximilian@gmail.com>, Hans de Goede <hansg@kernel.org>, 
 =?utf-8?q?Ilpo_J=C3=A4rvinen?= <ilpo.jarvinen@linux.intel.com>, 
 Jeff Johnson <jjohnson@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-wireless@vger.kernel.org, 
 platform-driver-x86@vger.kernel.org, ath12k@lists.infradead.org, 
 Jeff Johnson <jeff.johnson@oss.qualcomm.com>, 
 Dale Whinham <daleyo@gmail.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766190155; l=4338;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=+CciBVMmXK8RVQ3AsM9uUz7HTD5wQc1eKok9OBg5Eag=;
 b=u52ZKVtftt6PJMa6RlrN2Rjw0LqP83qxxnBf5Xuj14MIz4kx2Z7tM/MqtWKT+v1XrscZFilnq
 8O1h0JG1//zAsRXUuKz0MOBqJf8XYL99eblXKqZJmYlRB1DJqsILoKO
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series brings support for the Qualcomm-based Microsoft Surface
Pro 11 covering both the OLED and LCD variants.

Signed-off-by: Dale Whinham <daleyo@gmail.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
Changes in v5:
- Move the OLED variant description to keep the logical order [Krzysztof]
- Remove a T-b: tag as not applicable for a binding [Krzysztof]
- Remove another T-b: tag already covered by authorship [Krzysztof]
- Reference disable-rfkill in qcom,ath12k.yaml to fix dtbs_check failure [Krzysztof]
- Remove erroneously copied Copyright lines [Krzysztof]
- Add the R-b: tag from Dmitry for the aggregator_registry patch
- Link to v4: https://lore.kernel.org/r/20251218-surface-sp11-for-next-v4-0-7bcf83c1504a@gmail.com

Changes in v4:
- Re-order the denali entry in the aggregator_registry acpi_match table [Dmitry]
- Improve the bindings by splitting the LCD and OLED variants into 2 entries [Konrad]
- Enable i2c4 to make it accessible through i2c-tools [Konrad]
- Document the addresses for i2c0 and i2c4 like in romulus.dtsi [Konrad]
- Fix the clock-frequency for i2c0 based on DSDT/SSDT
- Drop i2c5 which is not found in the DSDT after double-checking
- Add the R-b: tag from Konrad for the SP11 device trees
- Link to v3: https://lore.kernel.org/r/20251218-surface-sp11-for-next-v3-0-875afc7bd3b7@gmail.com

Changes in v3:
- Update the compatible strings to document both the OLED and LCD variants
- Move the disable-rfkill property into ieee80211.yaml [Rob,Krzysztof]
- Reference commit c6a7c0b09d5f and detail the disable-rfkill patch description [Rob,Krzysztof]
- Switch to the renamed hamoa.dtsi and hamoa-pmics.dtsi [Dale]
- Improve the comments describing the 2 USB Type-C port location
- Update the speaker definition to describe only 2-speakers [Konrad]
- Drop output-low from the speaker definition [Konrad]
- Enable i2c0 to make it accessible through i2c-tools [Konrad]
- Delete a non-applicable comment about removable WLAN card [Konrad]
- Re-order a few nodes and fix indentation issues [Konrad]
- Squash one of the patches as suggested [Krzysztof]
- Drop the NAKed patch patch about a dpcd link rate quirk [Dmitry]
- Include the Reviewed-by: tags
- Link to v2: https://lore.kernel.org/all/20251201011457.17422-1-daleyo@gmail.com/

Changes in v2:
  - Dropped ATNA30DW01 patch as it was merged.
  - Split device tree into x1e (OLED)/x1p (LCD) specific *.dts files and move common code into x1-microsoft-denali.dtsi (patch 4).
  - Device tree now enables higher external monitor refresh rates/resolutions (patch 4).
  - Device tree now enables partially working audio output; requires alsa-ucm-conf and audioreach-topology definitions in userspace (patch 4).
  - Replaced 'Work around bogus maximum link rate' with a quirk-based approach (patch 5).
  - Improve the commit message about the disable-rfkill property in response to feedback (patch 6).

---
Dale Whinham (4):
      firmware: qcom: scm: allow QSEECOM on Surface Pro 11
      platform/surface: aggregator_registry: Add Surface Pro 11 (QCOM)
      arm64: dts: qcom: Add support for Surface Pro 11
      wifi: ath12k: Add support for disabling rfkill via devicetree

Jérôme de Bretagne (3):
      dt-bindings: arm: qcom: Document Microsoft Surface Pro 11
      dt-bindings: wireless: ieee80211: Add disable-rfkill property
      dt-bindings: wireless: ath12k: Allow disable-rfkill property

 Documentation/devicetree/bindings/arm/qcom.yaml    |   11 +
 .../bindings/net/wireless/ieee80211.yaml           |    6 +
 .../bindings/net/wireless/qcom,ath12k.yaml         |    5 +
 arch/arm64/boot/dts/qcom/Makefile                  |    4 +
 arch/arm64/boot/dts/qcom/x1-microsoft-denali.dtsi  | 1324 ++++++++++++++++++++
 .../dts/qcom/x1e80100-microsoft-denali-oled.dts    |   19 +
 .../boot/dts/qcom/x1p64100-microsoft-denali.dts    |   15 +
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 drivers/net/wireless/ath/ath12k/core.c             |    3 +
 .../platform/surface/surface_aggregator_registry.c |   18 +
 10 files changed, 1406 insertions(+)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251218-surface-sp11-for-next-626e327f7b33

Best regards,
-- 
Jérôme de Bretagne <jerome.debretagne@gmail.com>

