From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v4 0/3] add some node for amlogic c3
Date: Fri, 30 Aug 2024 13:26:07 +0800
Message-Id: <20240830-c3_add_node-v4-0-b56c0511e9dc@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAO9X0WYC/23MSwrCMBSF4a2UjI3c5IYkOnIfIiXNow1oI6kUp
 XTvph216PAc+P6JDD5HP5BzNZHsxzjE1JchDhWxnelbT6Mrm3DgAjRIarE2ztV9cp4KDgbVien
 ANCnimX2I77V2vZXdxeGV8meNj2x5/3dGRoFacF4wFEwiv5jHPbXRHm16kKU08o3msNe8aB0cB
 pCNaqz/1bjVuNdYNEqhUUlAFcRez/P8BfntYJokAQAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1724995568; l=1482;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=IUuuhUvQU5dAs9RfLllL5/UhHvsk0Yi/7MPZkoNINGU=;
 b=sLy0R/VKRQWb9D1RVwxovgKBbzbGnPv1YWx1+E11zczo1cNy8ZD6jpFK6l5WzoTjbI5OQygfm
 QAX524CQKMWA0RIYMr9i5PP5x2Bu9LYWa4nq91OfJi6wqYKNtQDAxGA
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some node for board AW409 and support board C308l AW419.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v4:
- Adjust the format of commit message.
- Link to v3: https://lore.kernel.org/r/20240823-c3_add_node-v3-0-3648376037f4@amlogic.com

Changes in v3:
- Change clkc_periphs node to the first.
- Link to v2: https://lore.kernel.org/r/20240820-c3_add_node-v2-0-8fd3f06b7bce@amlogic.com

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
 arch/arm64/boot/dts/amlogic/amlogic-c3.dtsi        | 488 ++++++++++++++++++++-
 5 files changed, 988 insertions(+), 3 deletions(-)
---
base-commit: 7a5d2ce79d1fc8535a6f10e51011ae9671bd86e8
change-id: 20240806-c3_add_node-420a37918f18

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

