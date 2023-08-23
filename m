From: Nikita Shubin <nikita.shubin@maquefel.me>
Subject: [PATCH 0/2] ata: pata_ep93xx: dt convert preparation fixes
Date: Wed, 23 Aug 2023 12:47:26 +0300
Message-Id: <20230823-ep93xx_pata_fixes-v1-0-d7e7229be148@maquefel.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAK7V5WQC/x3LUQqDMBCE4avIPjegCU1tr1JE1jjWfWgaslIC4
 t0b+/jP8O2kyAKlR7NTxldUPrFGd2korBxfMDLXJtta1/bWGaS7K2VMvPG4SIGaq4f3tz7Mfum
 ouokVZsocw3rKN+uGfB4p4y/q+hyO4wfSwjdCfAAAAA==
To: Sergey Shtylyov <s.shtylyov@omp.ru>, 
 Damien Le Moal <dlemoal@kernel.org>
Cc: linux-ide@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Nikita Shubin <nikita.shubin@maquefel.me>
X-Mailer: b4 0.12.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1692784059; l=769;
 i=nikita.shubin@maquefel.me; s=20230718; h=from:subject:message-id;
 bh=krhBKvq/7yPmNk8KhXgmxPtGwbeLJ0wWfNZMNkB+FyY=;
 b=R1E0ShJVgJ6+6M5JL8czSJJXXgcXGRt7mmcphEarVt02Mxf78/HoG4PiPHg3Aes8zSORUrvu2k/o
 jPQZMvG+DgxQIpAoqr7qUCOcuhAfGoary9BGk2rr9lANs5zi8ygA
X-Developer-Key: i=nikita.shubin@maquefel.me; a=ed25519;
 pk=vqf5YIUJ7BJv3EJFaNNxWZgGuMgDH6rwufTLflwU9ac=
X-Endpoint-Received: by B4 Relay for nikita.shubin@maquefel.me/20230718 with auth_id=65
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Sending some fixes in prior to "ep93xx device tree conversion" series,
as per Sergey request:

- simple replacement s/-ENXIO/-ENOMEM/ as it suits better.
- second is s/ep93xx_chip_revision()/soc_device_match(), so i can drop 
  ep93xx_chip_revision() entirely in later series.

Signed-off-by: Nikita Shubin <nikita.shubin@maquefel.me>
---
Nikita Shubin (2):
      ata: pata_ep93xx: fix error return code in probe
      ata: pata_ep93xx: use soc_device_match for UDMA modes

 drivers/ata/pata_ep93xx.c | 20 +++++++++++++-------
 1 file changed, 13 insertions(+), 7 deletions(-)
---
base-commit: 89bf6209cad66214d3774dac86b6bbf2aec6a30d
change-id: 20230823-ep93xx_pata_fixes-56e6678cd6f1

Best regards,
-- 
Nikita Shubin <nikita.shubin@maquefel.me>

