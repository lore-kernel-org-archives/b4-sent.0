From: Nizat Mikayilli <nacht@dxdmail.cc>
Subject: [PATCH 0/2] Input: wacom_w9000 - add support for Wacom WEZ01
Date: Sun, 08 Nov 2026 16:55:16 +0100
Message-Id: <20261108-b4-wacom-w9000-wez01-v1-0-c2b5e3466187@dxdmail.cc>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQrDIBBA0auEWWdgRoq0uUrIwtgxnUU1KMTQ4
 N0rWb7F/xcUySoFpuGCLIcWTbGDxwH8x8VNUN/dYMhYZnri+sDqfPpifRERVvkR4xpMEG+d42C
 hp3uWoOe9nZfW/vK+tM5mAAAA
X-Change-ID: 20261108-b4-wacom-w9000-wez01-bf2fec6aa1f6
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hendrik Noack <hendrik-noack@gmx.de>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794153317; l=1082;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=8XkiUPix4eRLdqxcZAiV0Titd2an3O/18ecr23mOFlE=;
 b=0V0q+sHIVc9jvjTC76iCBVo2+++7cuTURsWSlDAmS7xlYDHvBH72lt4A6hKdUPReWmzTRnD7y
 5TwdDJCnC1GA1CeapkWYaS7MgPAukdmd9FAWVLyjtPyrr+tHBYu9AD9
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Samsung Galaxy Tab S9 Wi-Fi uses a Wacom WEZ01 for its S Pen. It
has the same query and coordinate layout as the W9000 series, so these
patches add it to wacom_w9000.

The digitizer node for the tablet will be sent with its board series:
https://lore.kernel.org/r/20261022-gts9wifi-dts-v4-0-a361428fe59c@dxdmail.cc

I tested it on the tablet. I don't have a device with a W9002 or W9007A,
so for those it is only compile-tested.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
Nizat Mikayilli (2):
      dt-bindings: input: touchscreen: wacom,w9007a-lt03: Add Wacom WEZ01
      Input: wacom_w9000 - add support for Wacom WEZ01

 .../input/touchscreen/wacom,w9007a-lt03.yaml       |  1 +
 drivers/input/touchscreen/Kconfig                  |  2 +-
 drivers/input/touchscreen/wacom_w9000.c            | 53 ++++++++++++++++++----
 3 files changed, 47 insertions(+), 9 deletions(-)
---
base-commit: f7a8b89bc067fa1cbcd3312539bc0d61810d3280
change-id: 20261108-b4-wacom-w9000-wez01-bf2fec6aa1f6

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

