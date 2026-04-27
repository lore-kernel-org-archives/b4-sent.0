From: Harpreet Saini <sainiharpreet29@yahoo.com>
Subject: [PATCH v5 0/2] input: misc: Add PixArt PAJ7620 gesture sensor
Date: Mon, 27 Apr 2026 00:46:52 -0400
Message-Id: <20260427-paj7620-v5-v5-0-6f9bbe7b4ce3@yahoo.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADzq7mkC/yXMTQ5AMBBA4avIrDVphtbPVcSircFYIC0iEXdXL
 L/FexcE8kwB6uQCTwcHXuYIlSbgRjMPJLiLBpSoZY5arGYqNEpxKFFUxmJpMouUQwxWTz2f36x
 pf4fdTuS29wD3/QCGR6xQbgAAAA==
X-Change-ID: 20260426-paj7620-v5-79ab28a3b2e4
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Harpreet Saini <sainiharpreet29@yahoo.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1777265221; l=2621;
 i=sainiharpreet29@yahoo.com; s=20260427; h=from:subject:message-id;
 bh=2e+jaRWKKHaIzkuAYWVb2DBGxZhzSWlmnIKBT3yji3E=;
 b=qgjaXpOS+ZF5m+6PuaZVyxOyEdjTO9MG9TidqenodY1XQgwQ0ngUzLpRbH38GyRpWNhqLfFyR
 QrrJLv8ki30AvIo3d2bYKbDcx1OIbT6bgYaQ4KueoqCbCNFP1hR+MHt
X-Developer-Key: i=sainiharpreet29@yahoo.com; a=ed25519;
 pk=xht+vKyGRLShWSTBYoH2qBaDzKUL90zr77TVwj1ra9s=
X-Endpoint-Received: by B4 Relay for sainiharpreet29@yahoo.com/20260427 with auth_id=754
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for PixArt PAJ7620 gesture sensor

This series adds support for the PixArt PAJ7620 hand gesture sensor.
The sensor is connected via I2C and supports 9 different gestures. 
The first patch adds the DT bindings, and the second patch adds the 
driver itself.

Changes in v5:
  - Added this missing cover letter.
  - Included Reviewed-by tag for the bindings patch.
  - Linked to previous v4 discussion.
  - No functional changes since v4.

Changes in v4:
  - In pixart,paj7620.yaml dt-binding file added allOf: with $ref and 
    unevaluatedProperties
  - No changes in other files
  - Link to v4: https://lore.kernel.org/all/20260421041505.4548-2-sainiharpreet29@yahoo.com

Changes in v3:
  - Moved sensor power-up and paj7620_init() to input open/close callbacks
  - Implemented dynamic keymap support via 'linux,keycodes' DT property
  and enabled userspace adjustment via EVIOCSKEYCODE.
  - Updated YAML bindings to include mandatory vdd, vbus, and vled
  supplies.
  - Added gpio-controller properties to YAML for hardware completeness.
  - Link to v3: https://lore.kernel.org/all/20260418062241.104697-1-sainiharpreet29@yahoo.com

Changes in v2:
  - Moved driver from drivers/iio/light to drivers/input/misc
  - Updated DT bindings to include mandatory vdd, vbus, and vled supplies
  - Added Runtime PM support with autosuspend logic
  - Combined bindings and driver into a single series
  - Link to v2: https://lore.kernel.org/all/20260417052527.62535-1-sainiharpreet29@yahoo.com

Changes in v1:
  - Initial patch for dt-binding and driver was added to iio/light
    subsystem.
  - Link to v1: https://lore.kernel.org/all/20260413000308.7618-1-sainiharpreet29@yahoo.com 

Testing:
  - Hardware: Raspberry Pi 3
  - Method: Verified all hand gestures using 'evtest' to confirm correct
    input event reporting.

Signed-off-by: Harpreet Saini <sainiharpreet29@yahoo.com>

---
Harpreet Saini (2):
      dt-bindings: input: Add PixArt PAJ7620 gesture sensor
      input: misc: Add PixArt PAJ7620 gesture sensor driver

 .../devicetree/bindings/input/pixart,paj7620.yaml  |  84 +++++
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 drivers/input/misc/Kconfig                         |  12 +
 drivers/input/misc/Makefile                        |   1 +
 drivers/input/misc/paj7620.c                       | 338 +++++++++++++++++++++
 5 files changed, 437 insertions(+)
---
base-commit: bf9c95f3eeefb7fc4b4a6380cc23f1dca744e379
change-id: 20260426-paj7620-v5-79ab28a3b2e4

Best regards,
--  
Harpreet Saini <sainiharpreet29@yahoo.com>

