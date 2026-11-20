From: Arun Iyengar <aiyengar1990@gmail.com>
Subject: [PATCH v2 0/2] i2c: slave-eeprom: DT binding and OF match table
 for module autoload
Date: Fri, 20 Nov 2026 04:32:16 +0000
Message-Id: <20261120-i2c-slave-eeprom-of-match-v2-0-0444790a0b76@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42NQQ6CMBBFr0K6dkxbY0FX3MOwaMsUxlBKWmw0h
 LsLeAGXL3n//YUljISJ3YuFRcyUKIwbyFPBbK/HDoHajZnkUgkhOJC0kAadERCnGDwEB17Ptge
 jb641qtTVhbNtP0V09D7aj+bH6WWeaOc9uBs9pTnEz3Gexe7985MFCKhcqaRxXEl+rTuvaTjb4
 FmzrusXf+tkpdQAAAA=
X-Change-ID: 20261110-i2c-slave-eeprom-of-match-ba9fdb67a830
To: Andi Shyti <andi.shyti@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: Wolfram Sang <wsa+renesas@sang-engineering.com>, 
 =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 =?utf-8?q?Bj=C3=B6rn_Ard=C3=B6?= <bjorn.ardo@axis.com>, 
 linux-i2c@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795149136; l=2176;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=dzUxAQssdho4tD6qq5wNbGkHdJxPJCqUmcPON/OFUEo=;
 b=6i2g3LrFYRFOlSq5jd163SHJqTJxlY6Znko6UPXGWr1OE+LtpUFSiPn4wYW0AuQ2tsTahBHW7
 s9SvzyKe+JTC7RHJ9W7+spOTH4frNPAKO+VSbknes4rXvCm6Q7fYlNR
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A slave EEPROM backend described in the device tree binds only when the
driver is built in: the client announces an of: modalias and the module
has only i2c: aliases. Patch 2 adds the OF table.

Patch 1 documents the compatibles. Wolfram Sang asked for a YAML file
when Björn Ardö sent a patch for the same problem in 2021 [1], and on v1
he asked why compatibles without a binding should be added.

The binding keeps the driver's names, without a vendor prefix. Björn's
patch and the old DesignWare binding example (removed in 2020) used
"linux,slave-24c02"; that form binds too, because the I2C core strips
the prefix, but would not autoload with this table. I can switch to it
or list both if preferred.

This series was developed with Claude (Anthropic) as a coding assistant:
it investigated the problem, wrote the code, the binding and the commit
messages. I reviewed it, and it was tested on an Orange Pi Zero2 (H616)
as described in patch 2.

[1] https://lore.kernel.org/r/20210504135209.4757-1-bjorn.ardo@axis.com

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Changes in v2:
- New patch 1: DT binding for the compatibles (Wolfram Sang).
- Drop the <linux/mod_devicetable.h> include: <linux/i2c.h> already
  provides of_device_id (Uwe Kleine-König).
- Fix a NULL dereference in v1: a node that matches through a fallback
  compatible has no i2c id. Take the size and flags from
  i2c_get_match_data() and give the OF entries that data.
- Rebase onto i2c/i2c-next, new test results.
- Link to v1: https://patch.msgid.link/20261110-i2c-slave-eeprom-of-match-v1-1-8f762bf06205@gmail.com

---
Arun Iyengar (2):
      dt-bindings: i2c: Add the slave EEPROM backend
      i2c: slave-eeprom: Add an OF match table for module autoload

 .../devicetree/bindings/i2c/slave-eeprom.yaml      | 59 ++++++++++++++++++++++
 drivers/i2c/i2c-slave-eeprom.c                     | 34 +++++++++++--
 2 files changed, 89 insertions(+), 4 deletions(-)
---
base-commit: 9c19b1c078541841f6b68f815bb4ba5201ab2b65
change-id: 20261110-i2c-slave-eeprom-of-match-ba9fdb67a830

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

