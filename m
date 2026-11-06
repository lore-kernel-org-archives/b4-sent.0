From: Andrew Gigena <mail@andrewgigena.dev>
Subject: [PATCH v2 0/5] media: qcom: camss: Add SM8150 CAMSS support
Date: Fri, 06 Nov 2026 03:24:51 +0000
Message-Id: <20261106-sm8150-v7.4-rc1-camss-v2-0-39ee37787b00@andrewgigena.dev>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0K6dkhbQMSV9zAsxnaAmlBMB6uG9
 O4CHsDlS95/fxFMwRGLc7aIQNGxm/wK+pAJM6DvCZxdWWipj0rJEng8qUpCrPMSglFgcGQGW1h
 bkdSoainW7SNQ595799r+mJ+3O5l5i23G4Hiewmc/jmrz/n1EBRJqbKqixAa17i7obaBX73rym
 FuKok0pfQFJ665r0wAAAA==
X-Change-ID: 20261104-sm8150-v7.4-rc1-camss-d3dd5e02a170
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Robert Foss <rfoss@kernel.org>, Andi Shyti <andi.shyti@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bryan O'Donoghue <bod@kernel.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-i2c@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-media@vger.kernel.org, Andrew Gigena <mail@andrewgigena.dev>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793935531; l=3089;
 i=mail@andrewgigena.dev; s=20261104; h=from:subject:message-id;
 bh=qLVJbZNBqU02j9nDuuDniRv57jjqg5cA/kA8QxuVntM=;
 b=PYcC/EQh4zF8hn21EmdBlq17VpmgZQ2Cy3YQKqECxFxBxwEjdcRuRJvErOXRfOiPgGiLpqDCP
 3JJI6lxH6/GD/K7zuBWszqJYI4oiPWM9cN2uUitJrhKPBqzDL8LrtwQ
X-Developer-Key: i=mail@andrewgigena.dev; a=ed25519;
 pk=OMhlYIBaOEC8g4mJ4JCKy7kbg+lrwRxuujieZF8Ne6U=
X-Endpoint-Received: by B4 Relay for mail@andrewgigena.dev/20261104 with auth_id=1402
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds SoC-level CAMSS support for the Qualcomm SM8150
(Snapdragon 855), based on v7.4-rc1.

SM8150 contains four CSIPHY, four CSID (two full and two lite), two
VFE and two VFE-Lite instances. The blocks are close to the existing
SDM845/SM8250/SC8280XP implementations, so the driver change only adds
platform data and hooks the SoC into the existing Gen2 CSIPHY, Gen2
CSID and VFE 17x code paths. No new register programming sequences are
introduced.

The series documents the SM8150 CCI compatible, which the CCI nodes use
with qcom,msm8996-cci as the fallback. The patches are ordered bindings
first, then driver data, then the DT description. The series is
intentionally SoC-level only: it does not add a board DTS, camera
sensor drivers, or board-specific camera wiring.

Testing: with a local Pixel 4 (google-flame) board port and
out-of-tree IMX363, IMX481 and IMX520 sensor drivers, the rear wide
(IMX363) and rear tele (IMX481) cameras stream, and the front (IMX520)
path has produced frames. The board port itself is not part of this
series.

checkpatch reports no errors. The only warning is the new-binding
"MAINTAINERS needs updating" prompt, which is a false positive because
the existing CAMSS entry already covers qcom,*camss* bindings.

Changes in v2:
- Address the review comments from Sashiko, Bryan and Val.
- Drop the internal CAMCC *_src clocks from the binding, the example and
  the DTS; the binding now lists 27 clocks instead of 42.
- Remove clock-lanes from the CSI endpoints and use an unnumbered
  endpoint in the example, matching the other CAMSS bindings.
- Describe vdda-phy-supply as 0.88V and vdda-pll-supply as 1.2V.
- Move the CSIPHY supplies from the CSID resources to the CSIPHY
  resources, so they are enabled before the PHY is accessed.
- Add a separate fix for the VFE lite clock rates
- Tidy the CAMSS_8150 switch ordering.
- Link to v1: https://patch.msgid.link/20261104-sm8150-v7-4-rc1-camss-v1-0-7a9534a9a22f@andrewgigena.dev

Signed-off-by: Andrew Gigena <mail@andrewgigena.dev>
---
Andrew Gigena (5):
      dt-bindings: i2c: qcom-cci: Document SM8150 compatible
      dt-bindings: media: qcom,sm8150-camss: Add SM8150 CAMSS
      media: qcom: camss: Match VFE lite clocks by name prefix
      media: qcom: camss: Add support for SM8150
      arm64: dts: qcom: sm8150: Add CAMSS and CCI nodes

 .../devicetree/bindings/i2c/qcom,i2c-cci.yaml      |   2 +
 .../bindings/media/qcom,sm8150-camss.yaml          | 412 +++++++++++++++++++++
 arch/arm64/boot/dts/qcom/sm8150.dtsi               | 320 ++++++++++++++++
 .../platform/qcom/camss/camss-csiphy-3ph-1-0.c     |   2 +
 drivers/media/platform/qcom/camss/camss-vfe.c      |   3 +
 drivers/media/platform/qcom/camss/camss.c          | 267 +++++++++++++
 drivers/media/platform/qcom/camss/camss.h          |   1 +
 7 files changed, 1007 insertions(+)
---
base-commit: 6628e7d4c6b25c8d18f1345e3a20d21829aae7e4
change-id: 20261104-sm8150-v7.4-rc1-camss-d3dd5e02a170

Best regards,
--  
Andrew Gigena <mail@andrewgigena.dev>

