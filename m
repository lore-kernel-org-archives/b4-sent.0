From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH 0/3] hwrng: Add Cortina Systems CS7542 random number
 generator
Date: Mon, 23 Nov 2026 21:41:33 +0300
Message-Id: <20261123-b4-cs7542-trng-v1-0-92d9ffcee531@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMPQ6DMAxA4asgz1jC5qeiV0EdSDDgDqGKoUJC3
 J3Qjt/w3gEmUcXgmR0Q5aumS0igPAM/92ES1CEZuOCGiEt0FXp71BXjGsOE1JNrR/JD2TKk6BN
 l1P037F5/2+be4tf7Aud5AT2b1DVyAAAA
X-Change-ID: 20261123-b4-cs7542-trng-1a1b9f1cd392
To: Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795459294; l=2873;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=+5fdkP17MS5TugucRLc1SqQw0TM5TWxx5LmS9OinWPM=;
 b=EFCNN0/CVf4KaFDdPKiaayM2jbxBRe5MW+HGmsu9zePsIYfmrkoTcPS1ib5beUOjZ5cqYckJf
 NHISGsOTHKzBmTAzSFmdwY7uo8ot2660zzP6z6qMzLYAj7ZxTldlKVx
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Elliptic random number generator integrated in the CS7542,
based on the GPL vendor and OpenWrt implementations. The driver has no
platform Kconfig dependency. Its shared global scratch bit is updated
through a syscon regmap rather than an overlapping raw ioremap.

Polling is bounded. A nonblocking read starts or resumes a pending
transaction and returns immediately if data is not ready, instead of
entering the blocking poll path. Partial output and failure cleanup
preserve the caller's buffer bounds.

The existing OpenWrt quality setting of 512 is retained for review.
The output tests below only check access and obvious stuck output;
they do not characterize entropy or establish this quality estimate.
Feedback on that inherited policy is explicitly requested before
publication of a final version.

The three patches are the binding, the driver/Kconfig/Makefile and a
MAINTAINERS entry. They apply to Linux v7.4-rc4 without the pending
CS75xx platform or clock/pinctrl series. The TRNG syscon phandle can
refer to a generic syscon; the local board integration uses the new
CS7542 global-control binding being prepared separately.

Validation:
- binding schema, example compilation and style checks passed
- strict source checkpatch with --no-signoff: no errors/warnings/checks
- complete minimal ARM vmlinux and modules builds with both new
  drivers built in and modular, COMPILE_TEST=n, without the platform
- actual driver functions tested with mocked MMIO/regmap and UBSAN
- exact sources booted in a Linux 7.4-rc4 RAM integration kernel on
  Almond+, with platform v9, clock/pinctrl and the accepted watchdog

The first nonblocking read returned EAGAIN and subsequent reads
provided 4096 bytes. Output was neither all zero nor repetitions of one
16-byte block; no entropy estimate is inferred from those tests.
The final combined RAM test recorded 16 checks with no failures and
returned to installed OpenWrt 6.18.64 through the watchdog. Both CPUs
were online. The firmware was not flashed. Earlier incomplete or
experimental alarm runs are not counted as this successful test.

---
Fil Dunsky (3):
      dt-bindings: rng: Add Cortina Systems CS7542 TRNG
      hwrng: Add Cortina Systems CS7542 TRNG driver
      MAINTAINERS: Add Cortina Systems CS7542 TRNG support

 .../bindings/rng/cortina,cs7542-trng.yaml          |  38 +++++
 MAINTAINERS                                        |   7 +
 drivers/char/hw_random/Kconfig                     |  11 ++
 drivers/char/hw_random/Makefile                    |   1 +
 drivers/char/hw_random/cs75xx-trng.c               | 159 +++++++++++++++++++++
 5 files changed, 216 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-trng-1a1b9f1cd392

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

