From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v7 0/2] A proposal to add a gpio-locked clock driver.
Date: Sun, 27 Sep 2026 13:59:59 +0000
Message-Id: <20260927-feature-clock-guard-v7-0-8dd19568d9a2@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAF8huWoC/33PwU7DMAwG4FeZciYoceKk3Yn3QBwcN92iwYrSt
 QJNfXfSXQpqxPG35O+372KMOcVRHA93keOcxjRcS/BPB8Fnup6iTF3JAhQ4ZXQj+0i3KUfJ7wN
 f5Gmi3MkeFAEbDK1DUTY/c+zT10N9fSv5nMbbkL8fJbNep/97s5ZKOm08B6saG/xLyNMl5mceP
 sQKzrAhqFUdgRVhQItNh8aqHWI2pNxSR0xBlGYmRaQs4Q6xG+LB1RFbkNhyE4yH4DXvENyQVmM
 dwYJYoIAdG3JEO8T9QsDXEbe+o3zbmKBNZPiDLMvyAzG9vZ0QAgAA
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790517604; l=2916;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=TWibO/U7JZz/QwbWUVZ4iATu8yxVm0v3Ez0NVaeMK3s=;
 b=ZYv4YZhRda6DmmweFJ29otdnUK5ilAr4Rqy3RS6DNMS8kFkHXJ/ZTnke6SMssQZGDaWPpI116
 39SuSrgLI55Ag0//heGluE4zdymm2AyClPPyL6A98XljSQEbswC2C9y
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A gpio-locked clock represents an input clock, which state is determined
by a GPIO signal. It's similar to a gated-fixed-clock, but GPIO direction
is inverted. Consumers can use the output clock to wait until all input
clocks are locked and only then initialize / access dependent peripherals.

The usage example for such a driver is when peripherals depend on PLLs in
a FPGA, which can't be directly accessed by the CPU, but need a GPIO pin
to check whether clock is actually usable. E.g. some of the IPs might not
have a proper split between registers and IP core, which means that if an
external clock and/or PLL lock is missing and one tries to access the 
registers, the response never comes, thus the CPU stalls.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
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
      dt-bindings: clock: gpio-gate-clock: Add a new compatible string
      clk: Add gpio-locked clock driver

 .../devicetree/bindings/clock/gpio-gate-clock.yaml | 32 +++++++++++++++-
 drivers/clk/clk-gpio.c                             | 44 ++++++++++++++++++++--
 2 files changed, 71 insertions(+), 5 deletions(-)
---
base-commit: fd179f8a05be3ccae366b9b96e176b51fbe54aab
change-id: 20260318-feature-clock-guard-f20a2c35b965

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

