From: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
Subject: [PATCH 0/2] A proposal to add a virtual clock controller guard.
Date: Wed, 18 Mar 2026 17:43:38 +0000
Message-Id: <20260318-feature-clock-guard-v1-0-6137cb4084b7@bruker.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAErkumkC/x3MQQ5AMBBA0avIrE1SlTa4ilhUTZkQZIpIxN01l
 m/x/wORhClCkz0gdHHkbU0o8gz85NaRkIdk0EpbVRYVBnLHKYR+2fyM4+lkwKCV0740fW0NpHI
 XCnz/17Z73w9d668/ZQAAAA==
X-Change-ID: 20260318-feature-clock-guard-f20a2c35b965
To: Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, Vyacheslav Yurkov <uvv.mail@gmail.com>, 
 Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1773855836; l=1222;
 i=V.Yurkov.EXT@bruker.com; s=20260318; h=from:subject:message-id;
 bh=UIkIjQAzXj+Rj6KQbjxj4sOuqt8z+yoyvlPfZEgLIA4=;
 b=LOhlPYBN03T9ikQjtuqHG40YyaslhHGDQwLJK/1Z2S9vaPKHhsarcxEM8Gx0OcwvV9HSJUEyK
 mf/Ssd7fv/XCMmMQs7gWeZg1hRb9JI28Xx70kiw/EFJyzELw+jFO34o
X-Developer-Key: i=V.Yurkov.EXT@bruker.com; a=ed25519;
 pk=snJmgYVOKlp7aQtK9tWnEI7QTYxpPpJJvxdVsnxA7Fk=
X-Endpoint-Received: by B4 Relay for V.Yurkov.EXT@bruker.com/20260318 with auth_id=686
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The clock controller guard driver acts as clock provider and provides only
one clock that consumers can check to make sure whether all other conditions
are met in order to enable other peripehrals. This can be seen as 1-to-N
clock relation, thus consumers care only about one clock and not about N.

The usage example for such a driver is when peripherals depend on PLLs in
a FPGA, which can't be directly accessed by the CPU, but need a GPIO pin
to chekc whether clock is actually usable.

Signed-off-by: Vyacheslav Yurkov <uvv.mail@gmail.com>
Signed-off-by: Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>
---
Vyacheslav Yurkov (2):
      clk: Add clock controller guard
      dt-bindings: Add clock guard DT description

 .../bindings/clock/clock-controller-guard.yaml     |  79 +++++
 drivers/clk/Kconfig                                |  12 +
 drivers/clk/Makefile                               |   1 +
 drivers/clk/clkctrl-guard.c                        | 334 +++++++++++++++++++++
 4 files changed, 426 insertions(+)
---
base-commit: 4f3df2e5ea69f5717d2721922aff263c31957548
change-id: 20260318-feature-clock-guard-f20a2c35b965

Best regards,
-- 
Vyacheslav Yurkov <V.Yurkov.EXT@bruker.com>

