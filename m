From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v4 0/2] A proposal to add a gpio-locked fixed clock driver.
Date: Sun, 26 Jul 2026 17:40:23 +0000
Message-Id: <20260726-feature-clock-guard-v4-0-e9c8b372b71c@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIdGZmoC/33OSw6CMBCA4auQrq2ZvgBdeQ/joh0KNCiYAo2Gc
 HcLG2IkLv9J5puZSG+9sz05JxPxNrjedW0MeUgI1rqtLHVFbMKBpyBYTkurh9FbivcOG1qN2he
 05KA5CmVOqSJx8+lt6V6rer3Frl0/dP69Hglsmf73AqNAUyYyNBJyabKL8WNj/RG7B1nAwDdEM
 dhH+IIgV1LlhRISfhCxIfGXfUREBBiiBq1BavWFzPP8AcrEKWxBAQAA
X-Change-ID: 20260318-feature-clock-guard-f20a2c35b965
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Brian Masney <bmasney@redhat.com>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785087629; l=2038;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=0BGKt1m91nvEolRdnYWTfp/T+RfvOFvPKeLAV0WvmMg=;
 b=U5P+KGTE2a51jq9XrlPK1UhndU8uYVaFida+8VpsN/WEAM2lhyW8CHJUA/njEUAET9sGkUyTf
 TaKEPZWuIGJDZlAvpxvn7UA0Uo/lOzG3j4TQ04mdqdLe1qih/bt2q1M
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A gpio-locked fixed clock aggregates one or more input clocks and/or one
or more GPIOs. It's similar to a gated-fixed-clock, but GPIO direction is
inverted. Consumers can use the output clock to wait until all input
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
      dt-bindings: Add GPIO-locked fixed clock
      clk: Add gpio-locked fixed clock driver

 .../bindings/clock/gpio-locked-fixed-clock.yaml    |  59 ++++
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-gpio-locked.c                      | 306 +++++++++++++++++++++
 3 files changed, 366 insertions(+)
---
base-commit: 3dab139d4795f688e4f243e40c7474df00d329d9
change-id: 20260318-feature-clock-guard-f20a2c35b965

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

