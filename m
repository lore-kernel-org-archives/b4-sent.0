From: Gregory Fuchedgi <gfuchedgi@gmail.com>
Subject: [PATCH v2 0/2] hwmon: (tps23861) add class restrictions and
 semi-auto mode support
Date: Mon, 11 Aug 2025 09:13:14 -0700
Message-Id: <20250811-hwmon-tps23861-add-class-restrictions-v2-0-ebd122ec5e3b@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJoWmmgC/03NywrDIBBA0V8JrjvBBzG2q/5H6UJ0okKMxbEPC
 Pn3Sldd3s25OyOsCYldhp1VfCVKZeshTwNz0W4BIfneTHI5ccMNxHcuG7QHSWW0AOs9uNUSQUV
 qNbnWAQKjHCrHpTdmYt16VFzS5/e53XsvtWRosaL912cpJq7mUZiz0FqDgLA8XUQf0jVkm9bRl
 cyO4wt5ZQr0tgAAAA==
X-Change-ID: 20250808-hwmon-tps23861-add-class-restrictions-83ce3c02d885
To: Robert Marko <robert.marko@sartura.hr>, 
 Luka Perkov <luka.perkov@sartura.hr>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>, Jonathan Corbet <corbet@lwn.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-hwmon@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 Gregory Fuchedgi <gfuchedgi@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754928795; l=1529;
 i=gfuchedgi@gmail.com; s=20250811; h=from:subject:message-id;
 bh=BngNvQtxxPHzANuXTDA6edjPk7rZAtFM5WdYLG3It70=;
 b=A72Hmv6jDYqCbccWDuiRCxTupDmvpCXwUE2eoETQvNLrJQNL5w6+BIGbMk+WNvBkYuVhDX720
 cNF2R9o2EbaD5qiS0viNzdjDD0LmUssBk2/F8wmBY4GRJ1ATYsevy8X
X-Developer-Key: i=gfuchedgi@gmail.com; a=ed25519;
 pk=J3o48+1a2mUIebH8K4S3SPuR5bmamUvjlsf8onoIccA=
X-Endpoint-Received: by B4 Relay for gfuchedgi@gmail.com/20250811 with auth_id=484
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series introduces per-port device tree configuration with poe class
restrictions. Also adds optional reset/shutdown gpios.

Tested with hw poe tester:
 - Auto mode tested with no per-port DT settings as well as explicit port DT
   class=4. Tested that no IRQ is required in this case.
 - Semi-Auto mode with class restricted to 0, 1, 2 or 3. IRQ required.
 - Tested current cut-offs in Semi-Auto mode.
 - On/off by default setting tested for both Auto and Semi-Auto modes.
 - Tested fully disabling the ports in DT.
 - Tested with both reset and shutdown gpios defined, as well as with reset
   only, as well as with neither reset nor shutdown.

V1->V2:
 - code cleanup
 - split bindings into separate patch
 - use patternProperties
 - use labels instead of DT node names
 - add few comments for clarity

Signed-off-by: Gregory Fuchedgi <gfuchedgi@gmail.com>
---
Gregory Fuchedgi (2):
      hwmon: (tps23861) add class restrictions and semi-auto mode support
      dt-bindings: hwmon: update TI TPS23861 bindings with per-port schema

 .../devicetree/bindings/hwmon/ti,tps23861.yaml     |  86 +++++++
 Documentation/hwmon/tps23861.rst                   |   6 +-
 drivers/hwmon/tps23861.c                           | 249 ++++++++++++++++++++-
 3 files changed, 335 insertions(+), 6 deletions(-)
---
base-commit: b1549501188cc9eba732c25b033df7a53ccc341f
change-id: 20250808-hwmon-tps23861-add-class-restrictions-83ce3c02d885

Best regards,
-- 
Gregory Fuchedgi <gfuchedgi@gmail.com>

