From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/5] Add new Amlogic SoCs info defines.
Date: Fri, 12 Jul 2024 14:54:45 +0800
Message-Id: <20240712-soc_info-v1-0-05ba95929d5a@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADbTkGYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDc0ND3eL85PjMvLR83RQDQ0sLsyTjlFQDSyWg8oKi1LTMCrBR0bG1tQD
 Ub+yRWgAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720767287; l=938;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=PvK+uz7Ai6tJ90bdUtIav76E5cwMtKsTobObKEyJQhk=;
 b=NmECD3n5GJMLXnwBCHt6/k7L51BVXiv4OchwVFfnVoJoGiaEYCLk71XPDxK+/TIduxCOZMyeR
 8+FcVI9DInaAGOcpSUys66zVV0HlDCWD/is96VDFnU1DWoP029LI/hd
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add more Amlogic SoCs info defines, include S4, C3
T7, A4, A5.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (5):
      soc: amlogic: meson-gx-socinfo: add new SoCs id
      arm64: dts: amlogic: s4: add ao secure node
      arm64: dts: amlogic: c3: add ao secure node
      arm64: dts: amlogic: t7: add ao secure node
      arm64: dts: amlogic: a4: add ao secure node

 arch/arm64/boot/dts/amlogic/amlogic-a4-common.dtsi |  6 ++++++
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        |  5 +++++
 arch/arm64/boot/dts/amlogic/amlogic-t7.dtsi        |  6 ++++++
 arch/arm64/boot/dts/amlogic/meson-s4.dtsi          |  6 ++++++
 drivers/soc/amlogic/meson-gx-socinfo.c             | 10 ++++++++++
 5 files changed, 33 insertions(+)
---
base-commit: db067bd17c0124228c31c5fdfa29ec65239e692a
change-id: 20240711-soc_info-d01986b3de09

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

