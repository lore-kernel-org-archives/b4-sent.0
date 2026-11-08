From: Nizat Mikayilli <nacht@dxdmail.cc>
Subject: [PATCH 0/5] Input: s6sy761 - add support for ST FTS1BA90A
Date: Sun, 08 Nov 2026 09:33:52 +0100
Message-Id: <20261108-b4-s6sy761-fts1ba90a-v1-0-999b3cfaf82d@dxdmail.cc>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MTQqEMAxA4atI1gaaovXnKuIiapzJRqURcSjef
 YrLb/FeApOoYtAXCaJcarpvGVQWMH95+wjqkg3e+UDkWpwqtGC/JhCup9HEnWP0PHcVN+0ivoa
 cHlFWvd/tMD7PH0YeALRmAAAA
X-Change-ID: 20261108-b4-s6sy761-fts1ba90a-2ac94a78de25
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Henrik Rydberg <rydberg@bitmath.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Andi Shyti <andi.shyti@kernel.org>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Nizat Mikayilli <nacht@dxdmail.cc>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794126835; l=1250;
 i=nacht@dxdmail.cc; s=20261004; h=from:subject:message-id;
 bh=83BF4liHZfdBCSQ5dI7Z0ukjQe4jgkXlwnqUiFvL+jU=;
 b=bJaQIWdyyKYPeJTZwI5B/qd0c7K3R1yWORECZLNFSXHrSl8V6tQ+18NGeUBA9qHAGLmj4O03w
 IGDq9tF6IrODjmrHkErFOj9mxPvCks+ZyfYy6hTbO17vGCp1odnkOgM
X-Developer-Key: i=nacht@dxdmail.cc; a=ed25519;
 pk=Kay3P3pOJq5klUD+0/I8QX8JGOh0CeQXEwRVv7CMm4k=
X-Endpoint-Received: by B4 Relay for nacht@dxdmail.cc/20261004 with auth_id=1111
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The ST FTS1BA90A in the Samsung Galaxy Tab S9 Wi-Fi speaks the S6SY761
protocol, so this series adds it to s6sy761. Patches 1 and 2 are
standalone fixes.

The touchscreen node for the tablet will be sent with its board series:
https://lore.kernel.org/r/20261022-gts9wifi-dts-v4-0-a361428fe59c@dxdmail.cc

I tested it on the tablet. I don't have a device with an S6SY761, so
for that chip it is only compile-tested.

Signed-off-by: Nizat Mikayilli <nacht@dxdmail.cc>
---
Nizat Mikayilli (5):
      Input: s6sy761 - apply the touchscreen inversion and swap properties
      Input: s6sy761 - check the multitouch axis ranges
      dt-bindings: input: samsung,s6sy761: Add ST FTS1BA90A
      Input: s6sy761 - move chip differences into per-chip data
      Input: s6sy761 - add support for ST FTS1BA90A

 .../input/touchscreen/samsung,s6sy761.yaml         |   6 +-
 drivers/input/touchscreen/Kconfig                  |   3 +-
 drivers/input/touchscreen/s6sy761.c                | 190 ++++++++++++++++-----
 3 files changed, 156 insertions(+), 43 deletions(-)
---
base-commit: f7a8b89bc067fa1cbcd3312539bc0d61810d3280
change-id: 20261108-b4-s6sy761-fts1ba90a-2ac94a78de25

Best regards,
-- 
Nizat Mikayilli <nacht@dxdmail.cc>

