From: =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>
Subject: [PATCH v6 0/4] Add support for attaching a regulator to w1: ds2482
Date: Fri, 29 Nov 2024 14:25:52 +0100
Message-Id: <20241129-ds2482-add-reg-v6-0-bd95ad171e19@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAODASWcC/2XO0WrEIBAF0F9ZfK5FxzGaPvU/Sh9mdcwK3U3RE
 lqW/HvNQiGNvl3h3Ll3UblkruLldBeFl1zzfGtheDqJcKHbxDLHlgUoQN2ejBXQg6QYZeFJJtY
 GlKLo4iAa+iyc8vej8O295UuuX3P5efQvevv9q7LHqkVLJUPweB7pTBqG1+lK+eM5zFexVS2w4
 wAdh8bJkjLMDiO5Izd7jh03jXs1xGTGMKLFI8c978dj4+gsOVI+prEbb/d87LjdxifP3kTUBv9
 dX9f1F8ElUrSoAQAA
X-Change-ID: 20241111-ds2482-add-reg-fe13200ad7d6
To: Krzysztof Kozlowski <krzk@kernel.org>, Rob Herring <robh@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Stefan Wahren <stefan.wahren@chargebyte.com>, 
 Stefan Wahren <wahrenst@gmx.net>
Cc: Ben Gardner <bgardner@wabtec.com>, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, 
 =?utf-8?q?Kry=C5=A1tof_=C4=8Cern=C3=BD?= <cleverline1mc@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1732886921; l=1667;
 i=cleverline1mc@gmail.com; s=20241112; h=from:subject:message-id;
 bh=+SW8uSY4kk9jy3nBqPD/Tm8uG6EdIVWhrds3tTcNqnU=;
 b=u6WXxlaO9+lR/bChs8eqEQUIUnt8Llx1BqfeG3hnrBa7hwEUYcfc6+/SdfqLXAMmJFowXzGHW
 i9YFM5f6Nl8AvqmCNG9BlE2v7GU6844qRVqt41s/sUyqpHmsWgHj/63
X-Developer-Key: i=cleverline1mc@gmail.com; a=ed25519;
 pk=EJoEbw03UiRORQuCiEyNA8gH1Q6fIpEWnn/MyaWOWX0=
X-Endpoint-Received: by B4 Relay for cleverline1mc@gmail.com/20241112 with auth_id=275
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Kept the exit_w1_remove path as requested in the review.

Signed-off-by: Kryštof Černý <cleverline1mc@gmail.com>
---
Changes in v6:
- Returned the exit_w1_remove path in the probe function
- Link to v5: https://lore.kernel.org/r/20241129-ds2482-add-reg-v5-0-af8e83d41344@gmail.com

Changes in v5:
- Refactored the driver to use devm_kzalloc() instead of kzalloc()
- Link to v4: https://lore.kernel.org/r/20241125-ds2482-add-reg-v4-0-475a7a08df96@gmail.com

Changes in v4:
- Using dev_err_probe() instead of dev_err() for the regulator error.
- Corrected patch order.
- Link to v3: https://lore.kernel.org/r/20241124-ds2482-add-reg-v3-0-806df39c9454@gmail.com

Changes in v3:
- Switched from regulator_enable() to devm_regulator_get_enable()
- Removed obvious comments.
- Link to v2: https://lore.kernel.org/r/20241122-ds2482-add-reg-v2-0-a5a03ee74da7@gmail.com

Changes in v2:
- Removed property description
- Changed commit message of binding commit
- Link to v1: https://lore.kernel.org/r/20241115-ds2482-add-reg-v1-0-cc84b9aba126@gmail.com

---
Kryštof Černý (4):
      dt-bindings: w1: ds2482: Add vcc-supply property
      w1: ds2482: switch to devm_kzalloc() from kzalloc()
      w1: ds2482: Add regulator support
      w1: ds2482: Fix datasheet URL

 .../devicetree/bindings/w1/maxim,ds2482.yaml       |  2 ++
 drivers/w1/masters/ds2482.c                        | 26 ++++++++++------------
 2 files changed, 14 insertions(+), 14 deletions(-)
---
base-commit: 6d59cab07b8d74d0f0422b750038123334f6ecc2
change-id: 20241111-ds2482-add-reg-fe13200ad7d6

Best regards,
-- 
Kryštof Černý <cleverline1mc@gmail.com>

