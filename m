From: Colin Huang <u8813345@gmail.com>
Subject: [PATCH linux dev-6.18 0/3] add support for Delta E50SN12051
Date: Mon, 18 May 2026 16:08:23 +0800
Message-Id: <20260518-dev-6-18-e50sn12051-driver-v1-0-238e4e08a759@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPjICmoC/x2MQQoCMQxFr1KyNtJEOk69iriQNmpAqqRYBoa5u
 2F2/314b4UuptLhElYwGdr10xzoEKC87u0pqNUZOPIUE81YZeCEPiTF3oj9xGo6xPB0ppSFS+Z
 cwANfk4cue/wKb22/Jez2kWa4bdsfTtNnPXwAAAA=
X-Change-ID: 20260518-dev-6-18-e50sn12051-driver-37159e2c929c
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Colin Huang <colin.huang2@amd.com>, Colin Huang <u8813345@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1779091725; l=860;
 i=u8813345@gmail.com; s=20260202; h=from:subject:message-id;
 bh=K+UP5PEN+H1H0lqNkNcT/iYlDTj5N2JoBMlSwfoLBvE=;
 b=/Xa2kgizeagRVudikLBUCJklAX26CX2n31yoEPkSKSytW04GYkvqzYcezW30k0XL0vzAXmvtR
 LREi6l0kKtpC3Z5Id5jl28+gpm14qdQ31r/jREYP5SPRJslw9FGtzzp
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
base-commit: 542ae849596e5471bf4d489d4613924d88385146
change-id: 20260518-dev-6-18-e50sn12051-driver-37159e2c929c

Best regards,
-- 
Colin Huang <u8813345@gmail.com>

