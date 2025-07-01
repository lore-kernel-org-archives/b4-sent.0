From: Jack Cheng <Cheng.JackHY@inventec.com>
Subject: [PATCH 0/2] Add support for q50sn12072 and q54sn120a1
Date: Tue, 01 Jul 2025 12:03:44 +0000
Message-Id: <20250701-add-support-for-q50sn12072-and-q54sn120a1-v1-0-c387baf928cb@inventec.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKDOY2gC/x3N0QrCMAyF4VcZuTbQBuesryJelCXT3LS1cSKMv
 bthlx/8nLOBSVcxuA0bdPmqaS2OeBpgfuXyFFR2AwUawxQiZma0tbXaP7jUju8xWIkUJsJc2Hk
 +mL1MM6UkF75GBt9rXRb9HV/3x77/AcdVEv97AAAA
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jean Delvare <jdelvare@suse.com>, 
 Guenter Roeck <linux@roeck-us.net>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hwmon@vger.kernel.org, Jack Cheng <Cheng.JackHY@inventec.com>, 
 Jack Cheng <cheng.jackhy@inventec.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1751371491; l=1128;
 i=Cheng.JackHY@inventec.com; s=20250701; h=from:subject:message-id;
 bh=Geu8ummnogYTxNiBXGM/hmRr8QFOAK2JquaYcXupOng=;
 b=uryVKZGTrJl0If/sn1V3mR3ZOgEEAyr2PZdF64jHTusqTC1aP+Q3VmjWBflNBVsR1eytlVMjq
 dvOvawbcXykDak5tPpz0L11DV4K4EXlgKXcrGdDdBvRfnryRi6H87K2
X-Developer-Key: i=Cheng.JackHY@inventec.com; a=ed25519;
 pk=L+GNI15NJXj7JAu9YqFXp9hL3rwZWbBbjlEeDjPvm68=
X-Endpoint-Received: by B4 Relay for Cheng.JackHY@inventec.com/20250701 with auth_id=449
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Q54SN12072 and Q54SN120A1 are high-efficiency, high-density DC-DC power
module from Delta Power Modules.

The Q54SN12072, quarter brick, single output 12V. This product provides up
to 1200 watts of output power at 38~60V. The Q54SN12072 offers peak
efficiency up to 98.3%@54Vin.

The Q54SN120A1, quarter brick, single output 12V. This product provides up
to 1300 watts of output power at 40~60V. The Q54SN120A1 offers peak
efficiency up to 98.1%@54Vin.

Add support for them to q54sj108a2 driver.

Signed-off-by: Jack Cheng <Cheng.JackHY@inventec.com>
---
Jack Cheng (2):
      dt-bindings: trivial: Add q50sn12072 and q54sj108a1 support
      hwmon: (pmbus/q54sj108a2) Add support for q50sn12072 and q54sn120a1

 .../devicetree/bindings/trivial-devices.yaml       |  4 ++
 drivers/hwmon/pmbus/q54sj108a2.c                   | 51 +++++++++++++++++++++-
 2 files changed, 53 insertions(+), 2 deletions(-)
---
base-commit: d0b3b7b22dfa1f4b515fd3a295b3fd958f9e81af
change-id: 20250701-add-support-for-q50sn12072-and-q54sn120a1-a9c299e6d81d

Best regards,
-- 
Jack Cheng <Cheng.JackHY@inventec.com>

