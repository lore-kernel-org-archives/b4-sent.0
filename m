From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC 0/4] clk: hisilicon: add support for Hi3798MV200
Date: Fri, 16 Feb 2024 19:37:50 +0800
Message-Id: <20240216-clk-mv200-v1-0-a29ace29e636@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA5Jz2UC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIxMDI0Mz3eScbN3cMiMDA93kZIvkxFRjS7PUVAMloPqCotS0zAqwWdFKQW7
 OSrG1tQBqPn+cYAAAAA==
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: David Yang <mmyangfl@gmail.com>, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708083473; l=1516;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=xQgenU1RuH/1sl6zVXoRINQqPjQc+AObioNdVhirHEo=;
 b=97nMuwfwFk2N77rE/E+Z7xVKb7FuduTDlsPB/TDm/akUScmHkujGzAXrn8iw7+wSwLWbtovKE
 od9wqcKgyCICPE5pxHE76StiuaspaYhWRMxG4x5xUGGuKp0E+BzuDy1
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This SoC is similar to Hi3798CV200 with a few more clocks in CRG module.

Note this driver is still ongoing, many clocks are not registered in the
driver now. Feedback is welcomed, especially from HiSilicon people.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Yang Xiwen (4):
      dt-binding: clock: histb-clock: Add missing common clock and Hi3798MV200 specific clock definition
      clk: hisilicon: add CRG driver for Hi3798MV200 SoC
      dt-binding: clock: merge all hisilicon clock bindings to hisilicon,clock-reset-generator
      dt-binding: clock: hisilicon,clock-reset-controller: add Hi3798MV200 SoC support

 .../devicetree/bindings/clock/hi3660-clock.txt     |  47 ---
 .../devicetree/bindings/clock/hi3670-clock.txt     |  43 ---
 .../devicetree/bindings/clock/hi6220-clock.txt     |  52 ---
 .../devicetree/bindings/clock/hisi-crg.txt         |  50 ---
 .../clock/hisilicon,clock-reset-generator.yaml     | 175 +++++++++
 .../clock/hisilicon,hi3559av100-clock.yaml         |  59 ---
 drivers/clk/hisilicon/Kconfig                      |   8 +
 drivers/clk/hisilicon/Makefile                     |   1 +
 drivers/clk/hisilicon/crg-hi3798mv200.c            | 428 +++++++++++++++++++++
 include/dt-bindings/clock/histb-clock.h            |  21 +
 10 files changed, 633 insertions(+), 251 deletions(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240216-clk-mv200-cc8cae396ee0

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

