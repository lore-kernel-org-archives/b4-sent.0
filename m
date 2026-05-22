From: =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>
Subject: [PATCH v2 00/10] Microsoft Surface Pro 9 5G update
Date: Fri, 22 May 2026 12:43:16 +0200
Message-Id: <20260522-surface-sp9-5g-for-next-v2-0-dd9d477407f5@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEQzEGoC/4WNQQ6DIBBFr2JYdwydlKJd9R6NC8BBSSoYsMTGe
 PeiF+jyJe+/v7FE0VFij2pjkbJLLvgCeKmYGZUfCFxfmCHHOxfIIX2iVYYgzS2IAWyI4GldQDa
 tNFpze0PDynqOZN16ll9dYa0SgY7Km/HoZVnzQxtdWkL8nv/5esj/r/IVOLS9FSgEatvI5zAp9
 65NmFi37/sPHhuR8tUAAAA=
X-Change-ID: 20260520-surface-sp9-5g-for-next-7897cbb0f42c
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Johan Hovold <johan@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Krzysztof Kozlowski <krzk@kernel.org>, 
 =?utf-8?q?J=C3=A9r=C3=B4me_de_Bretagne?= <jerome.debretagne@gmail.com>, 
 Jens Glathe <jens.glathe@oldschoolsolutions.biz>, 
 Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Bartosz Golaszewski <brgl@kernel.org>, 
 Stephan Gerhold <stephan.gerhold@linaro.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779446623; l=1924;
 i=jerome.debretagne@gmail.com; s=20260520; h=from:subject:message-id;
 bh=irxIhZ6k1GrtmGJb1YpRm0XRzp3/Js4t6j+aLIg3dKs=;
 b=NOSLd7sF2MWxhkxnaNfms5y9agY3AwNtPGV7zT1dRmJiAcXdQ203Em7hbWMboSng7PkErw+m+
 Csz/RtuLHRTA6xgdWtNf4E+zboFeu7DU4+N9Sd0GfXEocwx4d8t74xT
X-Developer-Key: i=jerome.debretagne@gmail.com; a=ed25519;
 pk=3/JYhgYjGg5V9mlFxc0A0+pFiyjsuDB/TtDlNMId9fk=
X-Endpoint-Received: by B4 Relay for jerome.debretagne@gmail.com/20260520 with auth_id=785
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series updates the support for the Microsoft Surface 9 5G
(Arcata), bringing it more up-to-date and aligned with the other
sc8280xp models such as the Lenovo ThinkPad X13s.

As highlights, it finally enables the built-in screen, it fixes
Display Port alt mode on the top left-side USB-C port, it enables
the volume up/down keys and the lid switch.

Signed-off-by: Jérôme de Bretagne <jerome.debretagne@gmail.com>
---
Changes in v2:
- The panel-edp patch was accepted as a subset. Removed from this series [Doug]
- Update the backlight patch to keep only the necessary nodes
- Add R-by: tags and move a Fixes tag [Konrad]
- Strip details from the "Enable the eDP display" commit message [Konrad]
- Fix misleading commit message about USB-C orientation [Konrad]
- Link to v1: https://lore.kernel.org/r/20260520-surface-sp9-5g-for-next-v1-0-9df52552bf87@gmail.com

---
Jérôme de Bretagne (10):
      arm64: dts: qcom: sc8280xp-arcata: Enable backlight
      arm64: dts: qcom: sc8280xp-arcata: Enable the eDP display
      arm64: dts: qcom: sc8280xp-arcata: add USB-C orientation GPIOs
      arm64: dts: qcom: sc8280xp-arcata: Fix top USB-C DP alt mode
      arm64: dts: qcom: sc8280xp-arcata: Enable 4-lane DP support
      arm64: dts: qcom: sc8280xp-arcata: Add volume up/down GPIO keys
      arm64: dts: qcom: sc8280xp-arcata: Add lid switch
      arm64: dts: qcom: sc8280xp-arcata: model the PMU of the on-board wcn6855
      arm64: dts: qcom: sc8280xp-arcata: Switch to uefi rtc offset
      arm64: dts: qcom: sc8280xp-arcata: Drop duplicate DMIC supplies

 .../boot/dts/qcom/sc8280xp-microsoft-arcata.dts    | 279 ++++++++++++++++++---
 1 file changed, 243 insertions(+), 36 deletions(-)
---
base-commit: 028ef9c96e96197026887c0f092424679298aae8
change-id: 20260520-surface-sp9-5g-for-next-7897cbb0f42c

Best regards,
-- 
Jérôme de Bretagne <jerome.debretagne@gmail.com>

