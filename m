From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/3] add some node for amlogic c3
Date: Tue, 06 Aug 2024 18:27:13 +0800
Message-Id: <20240806-c3_add_node-v1-0-c0de41341632@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIH6sWYC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDCwMz3WTj+MSUlPi8/JRUXRMjg0Rjc0tDizRDCyWgjoKi1LTMCrBp0bG
 1tQDCFNWhXQAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chuan Liu <chuan.liu@amlogic.com>, 
 Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722940034; l=874;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=tnBvT/w43thSvlJ/YUxyz/XqxFCcr1JN1U9GgK3fKE8=;
 b=kq/KGDII0tJHN+mDp2Tjv86DYLPfsOhBkzOjXGiwUXsyK5Xpb5CCfO6uXDYJJbwKFRfm4Npuf
 PSQhgYpsd1wB2RaH68n0SqrnFVsFrUbwFMxNah4ftdxMnXtjTNmEgHT
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some node for board AW409 and support board C308l AW419.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Xianwei Zhao (3):
      dt-bindings: clock: fix C3 PLL input parameter
      arm64: dts: amlogic: add some device nodes for C3
      arm64: dts: amlogic: add C3 AW419 board

 .../bindings/clock/amlogic,c3-pll-clkc.yaml        |   7 +-
 arch/arm64/boot/dts/amlogic/Makefile               |   1 +
 .../boot/dts/amlogic/amlogic-c3-c302x-aw409.dts    | 249 +++++++++++
 .../boot/dts/amlogic/amlogic-c3-c308l-aw419.dts    | 278 ++++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        | 487 ++++++++++++++++++++-
 5 files changed, 1019 insertions(+), 3 deletions(-)
---
base-commit: 89933feccececf778cab56b1ec3d0916e9bbef3b
change-id: 20240806-c3_add_node-420a37918f18

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

