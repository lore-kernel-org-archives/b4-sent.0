From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH 0/2] power: bq24190: Add BQ24193 support
Date: Mon, 21 Apr 2025 23:27:32 -0500
Message-Id: <20250421-bq24193-v1-0-f125ef396d24@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALQaB2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyND3aRCIxNDS2PdZJOk1CQLy6SkJEszJaDqgqLUtMwKsEnRsbW1ABs
 W7d9ZAAAA
X-Change-ID: 20250421-bq24193-c4beb89bbb96
To: Sebastian Reichel <sre@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745296054; l=533;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=Fq2jiJWeXkpHf9bZrGaOYFjubx/HEzHAg8dgrWDcSb4=;
 b=GRCOGOgn3GfkllHsnZKOdlGAJrKKqIid2EUxM14fCUK0PTQ/+ZVq6zae/WIE7tjoVEC54LCsJ
 ICpJ2zHv9GfCQeKtXF+HLOQ0G4WkcGQChFbaCWO3imAExhWNhMvCq9E
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Aaron Kling (2):
      dt-bindings: power: supply: bq24190: Add BQ24193 compatible
      power: bq24190: Add BQ24193 support

 .../devicetree/bindings/power/supply/bq24190.yaml          |  1 +
 drivers/power/supply/bq24190_charger.c                     | 14 ++++++++++++++
 2 files changed, 15 insertions(+)
---
base-commit: a33b5a08cbbdd7aadff95f40cbb45ab86841679e
change-id: 20250421-bq24193-c4beb89bbb96

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

