From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/3] hwmon: (adt7410): Add ADT7422 support
Date: Wed, 15 Oct 2025 15:52:18 +0100
Message-Id: <20251015-dev-add-adt7422-v1-0-7cf72d3253ad@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIACK172gC/x2MQQqAIBAAvyJ7TlBJsr4SHTZday8VGhJIf086z
 GEOMxUyJaYMk6iQqHDm82iiOwF+x2MjyaE5GGWsVtrKQEViCI176I2R3vXrGBGd0gituhJFfv7
 jvLzvBxlJtHthAAAA
X-Change-ID: 20251015-dev-add-adt7422-c84b9faa801a
To: devicetree@vger.kernel.org, linux-hwmon@vger.kernel.org
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Guenter Roeck <linux@roeck-us.net>, 
 Cosmin Tanislav <demonsingur@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760539940; l=810;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=5FXCmHLwXXNVqUBOleAFVnQZfagtFHzvE7MB9x1wedM=;
 b=fgqNh15zVWNQU8YQFFLfp5IlBdzgzjfl3s20pLVM0bj82yLGcRbG6cpWDGjIujzhYUoq/qoKJ
 4xxS6eJgAyGCXZA/2Ww9T9J6IiFLC09MLXZ+xZnFjX3/XtpwreywtPL
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The main goal is to add support for the ADT7422 digital temperature
sensor which is similar to the ones already supported by the adt7410
driver.

While on it add the devices to trivial-devices and a proper of_id
table.

---
Nuno Sá (3):
      dt-bindings: trivial-devices: add ADT7410, ADT7420 and ADT7422
      hwmon: (adt7410): Add OF match table
      hwmon: (adt7410): Support adt7422 chip

 Documentation/devicetree/bindings/trivial-devices.yaml |  6 ++++++
 drivers/hwmon/Kconfig                                  |  6 +++---
 drivers/hwmon/adt7410.c                                | 11 +++++++++++
 3 files changed, 20 insertions(+), 3 deletions(-)
---
base-commit: 4b5bf30f28d5f8401f2314dcf28b9d9d5ff092cd
change-id: 20251015-dev-add-adt7422-c84b9faa801a
--

Thanks!
- Nuno Sá

