From: Alexandre Hamamdjian <azkali.limited@gmail.com>
Subject: [PATCH 0/4] Input: edt-ft5x06: robustness fixes for a FocalTech
 FT5426 on a marginal bus
Date: Thu, 23 Jul 2026 18:27:07 +0700
Message-Id: <20260723-b4-ft5426-v1-0-d4b4e32be042@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQqAIBBA4avErBNM7fcq0SJtrGlRoRZBdPesl
 h883gUeHaGHJrnA4UGe1iUiSxMwU7+MyGiIBsFFwUshmVbMhlyJgslaDlWeKVTaQuw3h5bO79V
 2v/2uZzThHcB9P2CgmFZtAAAA
X-Change-ID: 20260723-b4-ft5426-393d8514e4bf
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, Alexandre Hamamdjian <azkali.limited@gmail.com>, 
 Teguh Sobirin <teguh@sobir.in>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784806028; l=1711;
 i=azkali.limited@gmail.com; s=20260510; h=from:subject:message-id;
 bh=uvjbPDPruxrWtK8MfZxl0y9jWziTEYOYYxVOMFT3c5Y=;
 b=/HYVVo2ISake2MakeSgULvVpDrj82BqGO+ZAeI6j2bw5XKsip2vkp6mJLucoxMmTImBt+XdbE
 6u+E9b8whWLBkwopmUlsMjaGJlqmwKYnlvz9kT8g6D1gNpSx+2ENlWF
X-Developer-Key: i=azkali.limited@gmail.com; a=ed25519;
 pk=I0Z0IdCdQJqNGX+FQUnXhrHg950u3cM6Xzz3YT6JOyQ=
X-Endpoint-Received: by B4 Relay for azkali.limited@gmail.com/20260510 with auth_id=774
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The AYANEO Pocket DS drives its FocalTech FT5426 touch controller on a
Qualcomm GENI i2c controller that has no bus recovery and, on this
board, clock-stretches close to the controller timeout. This series
collects the robustness work that helps there, smallest and most
generic first:

  1. ignore contacts reported with an out-of-range slot id -- a generic
     correctness fix, independent of the board;
  2. document, and
  3. implement an optional no-regmap-bulk-read mode that reads the touch
     frame one register at a time, for controllers whose bus aborts long
     transfers;
  4. poll while a contact is down to recover a touch release dropped by
     a missed edge interrupt.

Patch 1 stands on its own; the rest are opt-in (DT property / chip
behaviour) and inert on healthy hardware. Feedback on whether the bus
mitigations belong here vs. in the i2c controller is welcome.

Signed-off-by: Alexandre Hamamdjian <azkali.limited@gmail.com>
---
Alexandre Hamamdjian (3):
      Input: edt-ft5x06 - ignore contacts with an out-of-range slot id
      dt-bindings: input: edt-ft5x06 - add no-regmap-bulk-read property
      Input: edt-ft5x06 - poll while a contact is down to recover dropped releases

Teguh Sobirin (1):
      Input: edt-ft5x06 - allow reading the touch frame one register at a time

 .../bindings/input/touchscreen/edt-ft5x06.yaml     |   8 +
 drivers/input/touchscreen/edt-ft5x06.c             | 200 +++++++++++++++++++--
 2 files changed, 196 insertions(+), 12 deletions(-)
---
base-commit: e98d21c170b01ddef366f023bbfcf6b31509fa83
change-id: 20260723-b4-ft5426-393d8514e4bf

Best regards,
--  
Alexandre Hamamdjian <azkali.limited@gmail.com>

