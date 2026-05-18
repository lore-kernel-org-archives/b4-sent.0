From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH linux dev-6.6 0/3] add support for Delta E50SN12051
Date: Mon, 18 May 2026 16:10:16 +0800
Message-Id: <20260518-dev-6-6-e50sn12051-driver-v1-0-8025fb61706e@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGnJCmoC/x2MwQqDMBBEfyXsuSlJwDT0V6QHSUZdKGnZYBDEf
 3eROb0Z3hzUIIxGb3OQoHPjX1XwD0N5neoCy0WZggvRDT7Zgm6jBoNr1QftbBHuEF1eGTmF5KZ
 E6v8FM+/390hfrttubvkZ6XOeF1uuKOR6AAAA
X-Change-ID: 20260518-dev-6-6-e50sn12051-driver-de7cec8280a8
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779091827; l=859;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=cPO+2Z78cAr68BCxS8UwzG/BZ4oa8eNTgVIcbGKSBQc=;
 b=SatA+iDWZIJssVMDEvg1QfFWXoawK5C9Ugje34VIENe19p/iZr/sXlfAVGLmaCBl30v1yauv1
 Wl+cPO8Ou6RBBNPKc20XfcXPUntkfvtecCgeg5imtqpm4yLZ4e3uMoz
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
change-id: 20260518-dev-6-6-e50sn12051-driver-de7cec8280a8

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

