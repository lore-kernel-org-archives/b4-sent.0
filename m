From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v5 0/2] A proposal to add a gpio-locked fixed clock driver.
Date: Tue, 15 Sep 2026 09:27:38 +0000
Message-Id: <20260915-feature-clock-guard-v5-0-42ab5dc3a6aa@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIoPqWoC/33OzQrCMAzA8VeRnq2kabtOT76HeGizTIsfk84NR
 fbudl6GODz+A/klL9FyityKzeIlEvexjc01h10uBB399cAyVrkFAhagVSlr9vcusaRzQyd56Hy
 qZI3gkbQN68KKvHlLXMfHR93tcx9je2/S83OkV+P0v9crCbJQ2lEwUJrgtiF1J04rai5iBHucE
 KtgHsERIbTGlpXVBn4QPSH5l3lEZwQUkQfvwXj7g5gJcVjMIyYjvKYyaIfBKfpChmF4A+BtX06
 GAQAA
X-Change-ID: 20260318-feature-clock-guard-f20a2c35b965
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Jyri Sarha <jsarha@ti.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789464467; l=2482;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=pHHLU5mEhTrcsZXkgtfWaWrdA6AqMjp+/cG3jZ+76cM=;
 b=V/uF4f5MjmuHdY7wLqc7A7A/h8M21hHv7OddW2uff3EnCqLHK/HtcjsaPRelROgCAKomQ7Otd
 83Tsh0nBuWcAqf25ZO4MnsL9C5OCVNEgb3X50qo4VX4IAM7oURwBeje
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A gpio-locked fixed clock represents an input clock, which state is 
determined by a GPIO signal. It's similar to a gated-fixed-clock, but
GPIO direction is inverted. Consumers can use the output clock to wait
until all input clocks are locked and only then initialize / access
dependent peripherals.

The usage example for such a driver is when peripherals depend on PLLs in
a FPGA, which can't be directly accessed by the CPU, but need a GPIO pin
to check whether clock is actually usable. E.g. some of the IPs might not
have a proper split between registers and IP core, which means that if an
external clock and/or PLL lock is missing and one tries to access the 
registers, the response never comes, thus the CPU stalls.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
Changes in v5:
- Use existing DT binding with an additional property instead of adding
  a new one
- The driver is simplified in a way that it represents the actual HW
  desgin without additional unrelated constructs
- Aggregation is removed, now it's one clock input, one clock output
- Link to v4: https://lore.kernel.org/r/20260726-feature-clock-guard-v4-0-e9c8b372b71c@bruker.com

Changes in v4:
- Removed driver specifics from DT binding
- Link to v3: https://lore.kernel.org/r/20260603-feature-clock-guard-v3-0-01cca0aa04a5@bruker.com

Changes in v3:
- Removed unnecessary dt bindings
- Improved HW description and commit messages
- Link to v2: https://lore.kernel.org/r/20260510-feature-clock-guard-v2-0-6c25458d5340@bruker.com

Changes in v2:
- Renamed to clk-gpio-locked to express intent.
- Provide enable() / is_enabled() operations so the clock behaves as
  expected
- Fixed DTS errors / warnings
- Link to v1: https://lore.kernel.org/r/20260318-feature-clock-guard-v1-0-6137cb4084b7@bruker.com

---
Vyacheslav Yurkov (2):
      dt-bindings: clock: gpio-gate-clock: Add a new compatible string
      clk: Add gpio-locked fixed clock driver

 .../devicetree/bindings/clock/gpio-gate-clock.yaml |  32 +++-
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-gpio-locked.c                      | 169 +++++++++++++++++++++
 3 files changed, 200 insertions(+), 2 deletions(-)
---
base-commit: 704340f1cd0dcef829eb62f5b48ae95a2ce17bdf
change-id: 20260318-feature-clock-guard-f20a2c35b965

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

