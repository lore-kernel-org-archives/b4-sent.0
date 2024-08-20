From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v2 0/3] add some node for amlogic c3
Date: Tue, 20 Aug 2024 17:41:55 +0800
Message-Id: <20240820-c3_add_node-v2-0-8fd3f06b7bce@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAONkxGYC/23MSwrCMBSF4a2UOzaSFzU6ch9SSkhu2ws2KYkEp
 WTvxo4d/gfOt0PGRJjh1u2QsFCmGFrIUwdusWFGRr41SC41N7xnTo3W+zFEj0xLbtXlKswkDLT
 HlnCi96E9htYL5VdMnwMv4rf+d4pgnDnuUQulRa/k3a7POJM7u7jCUGv9AiR7nACoAAAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724146916; l=1180;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=cS20O9LXg3AxB+iOazOUR7zUszo+e+eKg5CJ/BJIyYs=;
 b=dEY14KH7ypUWXvY00gpy9k1dyt91sftLPhTyXn/YCkHQkpRRd7iQ3NoQZlsiNGwHgCjzBMFMa
 qxe+0khm288APEdCK7iN2riSD4Go5XCsXZ6NiEtR5pJ0cMB6Pu2CfH+
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some node for board AW409 and support board C308l AW419.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v2:
- Delete unused sdio node in board level dts.
- Add the description of modifying the binding in commit msg.
- Add the reason why some node property fileds place at board level in commit msg.
- Link to v1: https://lore.kernel.org/r/20240806-c3_add_node-v1-0-c0de41341632@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: clock: fix C3 PLL input parameter
      arm64: dts: amlogic: add some device nodes for C3
      arm64: dts: amlogic: add C3 AW419 board

 .../bindings/clock/amlogic,c3-pll-clkc.yaml        |   7 +-
 arch/arm64/boot/dts/amlogic/Makefile               |   1 +
 .../boot/dts/amlogic/amlogic-c3-c302x-aw409.dts    | 233 ++++++++++
 .../boot/dts/amlogic/amlogic-c3-c308l-aw419.dts    | 262 +++++++++++
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        | 487 ++++++++++++++++++++-
 5 files changed, 987 insertions(+), 3 deletions(-)
---
base-commit: bfe05c592279e509a67c3ae305517859f3f5a58c
change-id: 20240806-c3_add_node-420a37918f18

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

