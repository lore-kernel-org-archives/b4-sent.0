From: Andy Chung <Andy.Chung@amd.com>
Subject: [PATCH linux dev-6.18 0/4] hwmon: (kb9002) backport Kandou KB9002
 retimer support
Date: Thu, 30 Jul 2026 17:07:55 +0800
Message-Id: <20260730-kb9002-backport-v1-0-41f472e52215@amd.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGsUa2oC/yWMywqDMBAAfyXsuSmbBEztrxQPeax2a4mSqAjiv
 zdtj8Mwc0ChzFTgLg7ItHHhKVVQFwHh6dJAkmNl0KgbtAbl6FtELb0L4zzlRRo0rSKnrIoWajV
 n6nn/HR/w5rTuItImm6u6Qff3ZfUvCst3C+f5AbHBdHeDAAAA
X-Change-ID: 20260730-kb9002-backport-30391ea171d7
To: openbmc@lists.ozlabs.org, joel@jms.id.au, andrew@codeconstruct.com.au
Cc: Andy Chung <Andy.Chung@amd.com>
X-Mailer: b4 0.15.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785402478; l=1054;
 i=Andy.Chung@amd.com; s=20260327; h=from:subject:message-id;
 bh=AETcoSpMJMkjMqd07nfckU1ICPSkADFXdUOJKb6ueBg=;
 b=RCEkeKZUxKOlK2MQm/FOBnwIDwpTBfwiJJpadeUyRqZ0qSZks9ejjcslyJuYv74Pjix6sM8L2
 bwB5fqwm25IClK4Am46qTAVY5SwI+nJ71aTcvljhMPqqnwSqLPSlzCK
X-Developer-Key: i=Andy.Chung@amd.com; a=ed25519;
 pk=X2gaHRnhU2q5hvMjkC6xmIcC03vKNvHY9CQRdsj9ecM=
X-Endpoint-Received: by B4 Relay for Andy.Chung@amd.com/20260327 with auth_id=696
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The upstream series was applied to hwmon-next on 2026-07-27.

Signed-off-by: Andy Chung <Andy.Chung@amd.com>
---
Andy Chung (4):
      dt-bindings: Add vendor prefix for Kandou
      dt-bindings: trivial-devices: Add Kandou KB9002
      hwmon: (kb9002) Add driver for Kandou KB9002 retimer
      hwmon: (kb9002) Add documentation

 .../devicetree/bindings/trivial-devices.yaml       |   2 +
 .../devicetree/bindings/vendor-prefixes.yaml       |   2 +
 Documentation/hwmon/index.rst                      |   1 +
 Documentation/hwmon/kb9002.rst                     |  64 +++
 MAINTAINERS                                        |   7 +
 drivers/hwmon/Kconfig                              |  11 +
 drivers/hwmon/Makefile                             |   1 +
 drivers/hwmon/kb9002.c                             | 459 +++++++++++++++++++++
 8 files changed, 547 insertions(+)
---
base-commit: c2b9fc3f7091157518a3ac2282a0a8bc797c227a
change-id: 20260730-kb9002-backport-30391ea171d7

Best regards,
--  
Andy Chung <Andy.Chung@amd.com>

