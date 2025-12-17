From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Subject: [PATCH v3 0/6] Microsoft Surface Pro 11 support
Date: Thu, 18 Dec 2025 00:56:36 +0100
Message-Id: <20251218-surface-sp11-for-next-v3-0-875afc7bd3b7@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADRDQ2kC/x3MOQqAQAxA0atIagNOBhe8ili4ZDTNKImKIN7dw
 fIV/z9grMIGbfaA8iUmW0zweQbTOsSFUeZkoIJKR65BOzUME6PtzmHYFCPfB1ZUsac61KP3kNp
 dOcj9f7v+fT8DnBloZwAAAA==
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
 Dale Whinham <daleyo@gmail.com>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1766015815; l=3060;
 i=jerome.debretagne@gmail.com; s=20251217; h=from:subject:message-id;
 bh=HR4qrmI9rceCWt7faPX8zYQtAYw4yuTbacR2hZ8jKj8=;
 b=t3BXpsJPHxSIlZjyA76+9GhmhP27qDDVarnKi/muuVipdCyPhGDLIzBzk4DJgGDFXkbCTKtLn
 vi5tRO1d+2BAlPqAqU/Gr8ilzjdiSp01/l7J36E32dkICd8KlD/Ss11
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=DcPD9n3oDMsPkt+12tU96swmGb5H86cxt+yiEVcUEGk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20251217 with auth_id=580
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series brings support for the Qualcomm-based Microsoft Surface
Pro 11 covering both the OLED and LCD variants.

Signed-off-by: Dale Whinham <daleyo@gmail.com>
Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
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
      platform/surface: aggregator_registry: Add Surface Pro 11
      arm64: dts: qcom: Add support for Surface Pro 11
      wifi: ath12k: Add support for disabling rfkill via devicetree

Jérôme de Bretagne (2):
      dt-bindings: arm: qcom: Document Microsoft Surface Pro 11
      dt-bindings: wireless: ieee80211: Add disable-rfkill property

 Documentation/devicetree/bindings/arm/qcom.yaml    |    8 +
 .../bindings/net/wireless/ieee80211.yaml           |    6 +
 arch/arm64/boot/dts/qcom/Makefile                  |    4 +
 arch/arm64/boot/dts/qcom/x1-microsoft-denali.dtsi  | 1326 ++++++++++++++++++++
 .../dts/qcom/x1e80100-microsoft-denali-oled.dts    |   20 +
 .../boot/dts/qcom/x1p64100-microsoft-denali.dts    |   16 +
 drivers/firmware/qcom/qcom_scm.c                   |    1 +
 drivers/net/wireless/ath/ath12k/core.c             |    3 +
 .../platform/surface/surface_aggregator_registry.c |   18 +
 9 files changed, 1402 insertions(+)
---
base-commit: 8f0b4cce4481fb22653697cced8d0d04027cb1e8
change-id: 20251218-surface-sp11-for-next-626e327f7b33

Best regards,
-- 
Jérôme de Bretagne <jerome.debretagne@gmail.com>

