From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH v2 0/2] A proposal to add a gpio-locked fixed clock driver.
Date: Sun, 10 May 2026 18:06:21 +0000
Message-Id: <20260510-feature-clock-guard-v2-0-6c25458d5340@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB3JAGoC/32NTQ6CMBBGr0Jm7Zi2/OrKexgWbRmgQamZQqMh3
 N3KAVy+l3zv2yAQOwpwzTZgii44PydQpwzsqOeB0HWJQQlViVw22JNeVia0D28nHFbNHfZKaGX
 z0lyqEtLyxdS791G9t4lHFxbPn+Mkyp/934sSBVYyr60pRFOY+mZ4nYjP1j+h3ff9C7X2O5S3A
 AAA
X-Change-ID: 20260318-feature-clock-guard-f20a2c35b965
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778436398; l=1674;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=Q/WCDKfdbN0bfbKBiTsXu/nT2ph+oMQHG9vFZrTe+28=;
 b=9sI8m7AMOU1hB1Gsotg8yQlFziYmA2hoYnJRQ2muNBU8CFQ3oNbFgQxoa0RNRbyPqVMj0tsZ0
 C3AkhgZf0F/A4HqFiCvJMOsLwFYrzSyz2AeMa8d6z9OCDGdM/o8jQqg
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
Changes in v2:
- Renamed to clk-gpio-locked to express intent.
- Provide enable() / is_enabled() operations so the clock behaves as
  expected
- Fixed DTS errors / warnings
- Link to v1: https://lore.kernel.org/r/20260318-feature-clock-guard-v1-0-6137cb4084b7@bruker.com

---
Vyacheslav Yurkov (2):
      clk: Add gpio-locked clock driver
      dt-bindings: Add GPIO locked fixed clock

 .../bindings/clock/gpio-locked-fixed-clock.yaml    |  77 ++++++
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clk-gpio-locked.c                      | 306 +++++++++++++++++++++
 3 files changed, 384 insertions(+)
---
base-commit: 917719c412c48687d4a176965d1fa35320ec457c
change-id: 20260318-feature-clock-guard-f20a2c35b965

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

