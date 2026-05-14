From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH linux dev-6.6 0/3] add support for Delta E50SN12051
Date: Thu, 14 May 2026 18:49:40 +0800
Message-Id: <20260514-backport-dev-6-6-e50sn12051-driver-v1-0-44d2ef6c18dd@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMWoBWoC/x2NwQrCMBBEfyXs2ZUkbXLwV8RDmqx1UdKy0VAo/
 XeXMqfH8GZ2aCRMDW5mB6HOjZeq4C4G8ivVmZCLMnjrow1uxCnl97rIFwt1jBoKtlXntcQi3En
 QpRCo5DwMUwQdWoWevJ0nd/hw/W3mlK8RHsfxBzA3DSyDAAAA
X-Change-ID: 20260514-backport-dev-6-6-e50sn12051-driver-1a55edcc33b6
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Guenter Roeck <linux@roeck-us.net>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1778755785; l=868;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=mV96jkCInMcJlapCpMzF/AaUl98egkYPeqsOYfjbenU=;
 b=ofc6r3neO6bv4jVclSqiWnA/JX1TkqbpJ8ysforIVHfV4uI65FQqEc7tqKPXAXuZBNQ+gjB6O
 dtXbXd/XdsAATO4f76Z+AhaGC6985SkfM40zwad9c/8WyuIEHhTgMAd
X-Developer-Key: i=u8813345@gmail.com; a=ed25519;
 pk=Zlg0WqpCw4qbswOqamTBTXIchwR/3SnYZpy7rjaGMdQ=
X-Endpoint-Received: by B4 Relay for u8813345@gmail.com/20260202 with auth_id=761
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Colin Huang <u8813345@gmail.com>
---
Colin Huang (3):
      dt-bindings: trivial-devices: Add Delta E50SN12051
      Documentation/hwmon: add Delta E50SN12051 documentation
      hwmon: (pmbus) add support for Delta E50SN12051

 .../devicetree/bindings/trivial-devices.yaml       |  2 +
 Documentation/hwmon/e50sn12051.rst                 | 81 ++++++++++++++++++++++
 Documentation/hwmon/index.rst                      |  1 +
 drivers/hwmon/pmbus/Kconfig                        |  9 +++
 drivers/hwmon/pmbus/Makefile                       |  1 +
 drivers/hwmon/pmbus/e50sn12051.c                   | 52 ++++++++++++++
 6 files changed, 146 insertions(+)
---
base-commit: e11fa6b1ff6c27c808d17e479bd7d5582e772062
change-id: 20260514-backport-dev-6-6-e50sn12051-driver-1a55edcc33b6

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

