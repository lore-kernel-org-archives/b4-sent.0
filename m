From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH 0/5] Power: Add power domain driver for S6 S7 S7D
Date: Fri, 22 Aug 2025 13:39:54 +0800
Message-Id: <20250822-pm-s6-s7-s7d-v1-0-82e3f3aff327@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKoCqGgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDCyMD3YJc3WIz3WJzIErRtTQ1SDM3MkhMTDZLUQJqKShKTcusABsXHVt
 bCwC3esbIXgAAAA==
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Jianxin Pan <jianxin.pan@amlogic.com>, Ulf Hansson <ulf.hansson@linaro.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-pm@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 "hongyu.chen1" <hongyu.chen1@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1755841286; l=1213;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=SWllvQUuWXUiZ37XKVOHkxwQQPRk+5jHJR1X7QQbqWU=;
 b=v6zP1X1MiyNWQVfGhjRcfGOC0lt9iG/FSAbPc+2Df+zqZf0YLjimp7/DcF5ze+DfN5jFWSfkw
 C5A8U4wNBWFDDsajqvt6DFrIfF7N0vlKPmgrOvHh1HqITJru5NZz9yJ
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add power controller driver support for Amlogic S6 S7 S7D SoC.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
hongyu.chen1 (5):
      dt-bindings: power: add Amlogic S6 S7 S7D power domains
      pmdomain: amlogic: Add support for S6 S7 S7D power domains controller
      arm64: dts: amlogic: s6: add power domain controller node
      arm64: dts: amlogic: s7: add power domain controller node
      arm64: dts: amlogic: s7d: add power domain controller node

 .../bindings/power/amlogic,meson-sec-pwrc.yaml     |  3 +
 arch/arm64/boot/dts/amlogic/amlogic-s6.dtsi        | 10 +++
 arch/arm64/boot/dts/amlogic/amlogic-s7.dtsi        | 10 +++
 arch/arm64/boot/dts/amlogic/amlogic-s7d.dtsi       | 10 +++
 drivers/pmdomain/amlogic/meson-secure-pwrc.c       | 95 ++++++++++++++++++++++
 include/dt-bindings/power/amlogic,s6-pwrc.h        | 29 +++++++
 include/dt-bindings/power/amlogic,s7-pwrc.h        | 20 +++++
 include/dt-bindings/power/amlogic,s7d-pwrc.h       | 27 ++++++
 8 files changed, 204 insertions(+)
---
base-commit: ffeebf7587f518a3717fad308cf735adbbcaba97
change-id: 20250820-pm-s6-s7-s7d-950f720aac6d

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

