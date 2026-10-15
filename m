From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v9 0/2] A proposal to add a gpio-enabled clock driver.
Date: Thu, 15 Oct 2026 14:22:49 +0000
Message-Id: <20261015-feature-clock-guard-v9-0-c1c05a498d9a@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALrh0GoC/43RzU7DMAwH8FeZcibIcb534j0QB8fJtmqwonSrQ
 NPenXSXglqhHf+W/LMtX8VQalcGsd1cRS1jN3T9qYX4tBF8oNO+yC63LBDQgVZB7gqdL7VIfu/
 5KPcXqlnuEAhZ2xSdFa3zs5Zd93VXX99aPnTDua/f9yGjmqr/e6OSIJ3SnpOBYJJ/SfVyLPWZ+
 w8xgSPOiFWwjuCEMFpjQ7bawALRM9J2WUd0Q0AxExCBIbtAzIx4dOuIaUiJHJL2mLziBWJnJCq
 7jtiGGKRkM2tyRAvE/ULQryNuOgd8DDopXRgXiH8A8Q0JOatoXciRlkh4AAnTdzREHYoGJPUHu
 d1uP0YK9K+aAgAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792074172; l=3490;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=U0moA7hG8cZFQMuoS6kww9Ed1c45Em2nKl7I+kC/DQc=;
 b=+tp+9bGYxNzSkl6RzAruP7+oILQQQasT8aKHZNYCHQI/XL5K4pHrnP/udqFIsCtkyn1pkacQ6
 +V8n30+3TtJCmcHrqc8OkhKYpJDowZNEr1jXkM3nJxwCvqsOOT4VjSS
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A gpio-enabled clock represents an input clock, which state is determined
by a GPIO signal. It's similar to a gated-fixed-clock, but GPIO direction
is inverted. Consumers can use the output clock to wait until the clock
is ready and only then initialize / access dependent peripherals.

The usage example for such a driver is when peripherals depend on PLLs in
a FPGA, which can't be directly accessed by the CPU, but need a GPIO pin
to check whether clock is actually usable. E.g. some of the IPs might not
have a proper split between registers and IP core, which means that if an
external clock and/or PLL lock is missing and one tries to access the 
registers, the response never comes, thus the CPU stalls.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
Changes in v9:
- Changed wordking from "locked" to "enabled" to be more generic
- Use a separate DT schema file similar to other clock drivers
- Add a timeout for polling in enable()/prepare()
- Depending on whether GPIO can sleep or not use prepare() or enable()
  set of ops respectively.
- Decouple the implementation from exisiting drivers
- Link to v8: https://lore.kernel.org/r/20260927-feature-clock-guard-v8-0-630938e302a1@bruker.com

Changes in v8:
- Fix return value of clk_gpio_locked_prepare()
- Link to v7: https://lore.kernel.org/r/20260927-feature-clock-guard-v7-0-8dd19568d9a2@bruker.com

Changes in v7:
- Fix compatibility strings and schema errors.
- Update GPIO pin name
- Link to v6: https://lore.kernel.org/r/20260927-feature-clock-guard-v6-0-007983b13ec2@bruker.com

Changes in v6:
- Debug messages dropped.
- The new driver is now an extension of exising clk-gpio drivers.
- The controller doesn't enable the parent clock, the consumer is
  supposed to do that instead.
- Link to v5: https://lore.kernel.org/r/20260915-feature-clock-guard-v5-0-42ab5dc3a6aa@bruker.com

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
      dt-bindings: gpio-enabled-clock: Add a new binding
      clk: Add gpio-enabled clock driver

 .../bindings/clock/gpio-enabled-clock.yaml         |  53 +++++++
 drivers/clk/clk-gpio.c                             | 161 +++++++++++++++++++++
 2 files changed, 214 insertions(+)
---
base-commit: 0fcb05b72344f40806cbe810de8872f1698bf053
change-id: 20260318-feature-clock-guard-f20a2c35b965

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

