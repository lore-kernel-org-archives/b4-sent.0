From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v6 0/4] (subset) Add OnePlus 6T display (Samsung S6E3FC2X01
 DDIC with AMS641RW panel)
Date: Mon, 03 Nov 2025 12:45:49 +0100
Message-Id: <20251103-s6e3fc2x01-v6-0-d4eb4abaefa4@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO2VCGkC/1XQQY4CIRCF4asY1oOpKrpocOU9zCxaLJSNThpDW
 k3ffdBkJrB8JN+fFC+VZU6S1W7zUrOUlNPtWof92qhwma5n0elUtyIgBk9GZysmBloAdfTMcHR
 EUVhV8DNLTMsndviu+5Ly/TY/Pu2C79e/DLeZghq0J28A7WhdHPdpSfdteKp3pNA/RADXQaqQU
 MKEJw7kfA9NA9F20FQYBKJha48eTA+HBhJ2cKiQxYgQBuvc1ENuYfdVhSt00TkmseOAzY3ruv4
 CrwBxa4YBAAA=
X-Change-ID: 20250923-s6e3fc2x01-f9550b822fe5
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=3104; i=david@ixit.cz;
 h=from:subject:message-id; bh=AgahBeRDzHAB1SXfgZ9yKWZumJfd92YC3BygZ9e56MI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpCJXu4byttUzIuDA2fEQgfhoHnn3nNGTtxEejQ
 xV6GaI9vHeJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaQiV7gAKCRBgAj/E00kg
 cvCKD/4pdKlJcB+YTv3DArN9etk9xSYly4awIoh7HNdtFA9EgLoEVH232tYTz5uVEbrT8eFPD5X
 HizKEDjAhC+J4X6ZBOuUrnKrIxFgYrl6/yX+FqnQc+DnxsQuQBqfn3LEIzLqglFwYoXEAvBRk3g
 HiDR4TLZnwjXnPSeMQLGiB+vOXptmLf4WkCHj/CPYMZQ1siJRDblL2w7JpAGDT9M9KIeVg5H49D
 psayxzWl605QNW7iz6EHM1dSO9oSxn7YONFvnXjGPO5Vc7X9Fl8cRQXLZsOmWiA/ezflYp3UqHD
 3kPJsM9aDqMHInqV/259VX8Z1hgfAiqopr3Jx/a4iXHNQLXQY+YNm7L+aa+H8Vx+EGwp74NKmgi
 Dhfp6LoTxYShRmDRmAOLRMqUHaESKxseX1JxMLxA1mCnXnhtfsqL5gWJcqFjGShdnFTnDhVxHuk
 4YPxHMSYYaObDODpIBPWD8jWuYlPzNmikyJRHsX/tNAynd/X83LzS7bAE/wlCRz6e04/07bKQ7A
 JnzxDbbeLnd3ESPePP0NPyH+fl9TDw5fcYFreR9s3TVDcM/n4WJ+zBsGRXZnqwgQ2q84UIeyNw4
 9FZP93Y+PtcJFiYAQJXQZUQENK2GAnYCZfnB2ULscjBX47dHFxRr5oiRm94254bRFx7IaR7T+5e
 Yofkl24HjXACFWQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset enables the display on the OnePlus 6T smartphone.

(subset) Patches document the panel, pinctrls, and GPIOs.

Since the display node is shared between the OnePlus 6 and 6T,
the following warning appears:

..sdm845-oneplus-enchilada.dtb: panel@0 (samsung,sofef00): 'poc-supply', 'te-gpios', 'vci-supply' do not match any of the regexes: '^pinctrl-[0-9]+$'

This will be addressed in a follow-up patch, as the SOFEF00 DDIC also
requires additional overhaul to properly initialize and function in mainline.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v6:
- Rebase on top of next-20251103 and resolve conflicts due to another
  OnePlus 6 fix being merged.
- Link to v5: https://lore.kernel.org/r/20251023-s6e3fc2x01-v5-0-8f8852e67417@ixit.cz

Changes in v5:
- Squashed removal of compatible from simple DSI panel with introduction
  of the panel definition. (Konrad)
- Link to v4: https://lore.kernel.org/r/20251021-s6e3fc2x01-v4-0-5e3ee21c688a@ixit.cz

Changes in v4:
- Use refcounted allocation in place of devm_kzalloc()
- Added include drm_probe_helper (Raihan)
- Corrected te-gpio value from 30 to 10.
- Removed legacy compatible samsung,s6e3fc2x01 from the driver (Dmitry)
- Removed old compatible also from panel-simple-dsi enum.
- Link to v3: https://lore.kernel.org/r/20251016-s6e3fc2x01-v3-0-ce0f3566b903@ixit.cz

Changes in v3:
- Use mipi_dsi_dcs_set_display_brightness_large (Konrad)
- added legacy compatible samsung,s6e3fc2x01 into the driver (Dmitry)
- extended compatible string to
  "samsung,s6e3fc2x01-ams641rw", "samsung,s6e3fc2x01" (Dmitry)
- Brought back
  "dt-bindings: display: panel-simple-dsi: Remove Samsung S6E3FC2 compatible"
- Link to v2: https://lore.kernel.org/r/20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz

Changes in v2:
- Dropped the gpio reset polarity change as suggested (Jens and Dmitry).
- Fixed unused warnings (kernel test robot).
- Added a pinctrl config for the VCI and POC supply.
- Removed patch "dt-bindings: display: panel-simple-dsi: Remove Samsung S6E3FC2 compatible"
  while the compatible is used in device-tree, but without any driver
  serving it, do not touch it (Rob)
- Added more details into the device-tree about the OnePlus 6T panel properties
- Put display gpio -pins into one -state block.
- Link to v1: https://lore.kernel.org/r/20250925-s6e3fc2x01-v1-0-9293016768f7@ixit.cz

---
Casey Connolly (1):
      arm64: dts: qcom: sdm845-oneplus: Update compatbible and add DDIC supplies

David Heidelberg (3):
      arm64: dts: qcom: sdm845-oneplus: Group panel pinctrl
      arm64: dts: qcom: sdm845-oneplus: Implement panel sleep pinctrl
      arm64: dts: qcom: sdm845-oneplus: Describe TE gpio

 .../arm64/boot/dts/qcom/sdm845-oneplus-common.dtsi | 113 +++++++++++++++++----
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts |   2 +-
 2 files changed, 93 insertions(+), 22 deletions(-)
---
base-commit: 9823120909776bbca58a3c55ef1f27d49283c1f3
change-id: 20250923-s6e3fc2x01-f9550b822fe5

Best regards,
-- 
David Heidelberg <david@ixit.cz>

