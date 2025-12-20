From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Subject: [PATCH v6 0/4] Microsoft Surface Pro 11 support
Date: Sat, 20 Dec 2025 16:26:28 +0100
Message-Id: <20251220-surface-sp11-for-next-v6-0-81f7451edb77@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACTARmkC/43NSwrDIBSF4a0Ex7X4iBo66j5KB2quidA80FRSQ
 vZek1EolHb4H7jfXVCE4CGiS7GgAMlHP/Q55KlAttV9A9jXuREjTFBGKxyfwWkLOI6UYjcE3MM
 8YckkcKacMpyjfDsGcH7e3ds9d+vjNITX/ibxbf0lJo4JrpTQzipTc6OuTaf942yHDm1iKv9Sy
 qwoY13FLRWk1J+KOCiMfFNEVqgkUhhwFTh+VNZ1fQN9AHowRgEAAA==
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
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766244471; l=4231;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=DPZHoH7vOJ/r2CeJeriCWNUsS83oy/VS5P0MpcoRIXQ=;
 b=QKadjW+4PC8FotW4AvCCGOY4/QyN7Ug8REPTA1QxIbDM8a2bs4972VohIFWuqLsQROKZ+l/uv
 Cyl7ERHj3fdCsLltxURtkIhvNtUAObFU/92jjm1F6IXUPrRzHJFIdV8
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series brings support for the Qualcomm-based Microsoft Surface
Pro 11 covering both the OLED and LCD variants.

Signed-off-by: Dale Whinham <daleyo@gmail.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
Changes in v6:
- Remove the disable-rfkill property and patches entirely from this patchset [Bryan, Krzysztof]
- Add the R-b: tag from Krzysztof for the denali compatibles
- Link to v5: https://lore.kernel.org/r/20251220-surface-sp11-for-next-v5-0-16065bef8ef3@gmail.com

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
Dale Whinham (3):
      firmware: qcom: scm: allow QSEECOM on Surface Pro 11
      platform/surface: aggregator_registry: Add Surface Pro 11 (QCOM)
      arm64: dts: qcom: Add support for X1-based Surface Pro 11

Jérôme de Bretagne (1):
      dt-bindings: arm: qcom: Document Microsoft Surface Pro 11

 Documentation/devicetree/bindings/arm/qcom.yaml    |   11 +
 arch/arm64/boot/dts/qcom/Makefile                  |    4 +
 arch/arm64/boot/dts/qcom/x1-microsoft-denali.dtsi  | 1322 ++++++++++++++++++++
 .../dts/qcom/x1e80100-microsoft-denali-oled.dts    |   19 +
 .../boot/dts/qcom/x1p64100-microsoft-denali.dts    |   15 +
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 .../platform/surface/surface_aggregator_registry.c |   18 +
 7 files changed, 1390 insertions(+)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251218-surface-sp11-for-next-626e327f7b33

Best regards,
-- 
Jérôme de Bretagne <jerome.debretagne@gmail.com>

