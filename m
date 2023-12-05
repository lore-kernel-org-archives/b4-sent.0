From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v3 0/2] Add support for LTC4282
Date: Tue, 05 Dec 2023 16:22:54 +0100
Message-Id: <20231205-ltc4282-support-v3-0-e0877b281bc2@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAE5Ab2UC/03MQQ6DIBBA0auYWXcMA6LoqvdouiB0VBIFA9o0M
 d69pKsu3+L/EzInzxmG6oTEb599DAXqVoGbbZgY/asYpJCKSDa47K6RRmI+ti2mHY2jttOsSAs
 DpdoSj/7zOz6exWOKK+5zYvv3IUGaeqFranVvOoUKwxFine3dBrvEqXZxhev6ArTQuAKfAAAA
To: linux-hwmon@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-doc@vger.kernel.org
Cc: Jean Delvare <jdelvare@suse.com>, Guenter Roeck <linux@roeck-us.net>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jonathan Corbet <corbet@lwn.net>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701789775; l=2306;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=zmMe6JBH09XXMGADR7GVSPNl3I74k767y2uX7Ridnpw=;
 b=y+rnkM3pXhxCNJfuqsOWQ7W778iLQ8AibszEbiqJrlzeuh9DYCA2OvLdY63+O4C1a8SrnRN2o
 XOUeKCuhWZoDLTqOagsansAxcS3ciSBeCS5V1KB0hwZ2z5kxWM4I0dn
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

v1:
 * https://lore.kernel.org/linux-hwmon/20231110151905.1659873-1-nuno.sa@analog.com/

v2:
 * https://lore.kernel.org/linux-hwmon/20231124-ltc4282-support-v2-0-952bf926f83c@analog.com 

Changes in V3:
- Bindings:
   * Remove 'default' from string types;
   * Update gpios descriptions and removed leftovers from when they were
     integer types.
   * Dropped gpio function. With that, adi,gpio3-mode and adi,gpio-alert were
     dropped.
- Driver:
   * Make all clock ops static;
   * Dropped macro to create debugfs attributes;
   * Dropped GPIO support;
   * Removed regulator consumer header (leftover from v1).

There are still some possible interfaces which are dubious from an hwmon
point view. Namely:

* fet_short_fault
* fet_bad_fault
* power1_good

power1_good and fet_short can be "monitored" with gpio1 and 2
respectively so maybe we could remove the. OTHO, some users might want
the pins free for GPIO usage. fet_bad_fault is a status bit (we also have it in
fault_logs) that might be meaningful to monitor (I think).

Also to note, I'm still seeing the following sparse issue:

"CHECK   drivers/hwmon/ltc4282.c
drivers/hwmon/ltc4282.c:805:34: warning: dubious: x & !y
drivers/hwmon/ltc4282.c:895:34: warning: dubious: x & !y" 

However, this does not look to be directly related with the driver. It's
on FIED_PREP() taking values like !val or !!val.

I'm also removing the GPIO maintainers/reviewers from Cc since there's no
gpiochip support anymore. If not adequate, I'll Cc them again...

---
Nuno Sa (2):
      dt-bindings: hwmon: Add LTC4282 bindings
      hwmon: ltc4282: add support for the LTC4282 chip

 .../devicetree/bindings/hwmon/adi,ltc4282.yaml     |  142 ++
 Documentation/hwmon/index.rst                      |    1 +
 Documentation/hwmon/ltc4282.rst                    |  108 ++
 MAINTAINERS                                        |    8 +
 drivers/hwmon/Kconfig                              |   11 +
 drivers/hwmon/Makefile                             |    1 +
 drivers/hwmon/ltc4282.c                            | 1705 ++++++++++++++++++++
 7 files changed, 1976 insertions(+)
---
base-commit: 44482310b7f8ac4cd8fa7be4cee8c1b260ea5ee9
change-id: 20231124-ltc4282-support-8c1675e31508
--

Thanks!
- Nuno Sá

