From: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
Subject: [PATCH v4 0/2] m68k: coldfire: Add RNG support for MCF54418
Date: Wed, 26 Nov 2025 08:08:08 +0100
Message-Id: <20251126-b4-m5441x-add-rng-support-v4-0-5309548c9555@yoseli.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAFinJmkC/43NwQ6CMAyA4VchO1uzlSLgyfcwHoYdsEQZ2ZBAC
 O/u4KQX4/Fv2q+LCMZbE8Q5WYQ3ow3WdTHokIh7q7vGgOXYAiVmSskcKoJnRqQm0MzguwbCq++
 dH0DWXBVMEpXUIt733tR22u3rLXZrw+D8vL8acZv+o44IEupS8anIihSr8jK7YB726HwjNnZMP
 yikX1S6UUR53GTNmH9R67q+AZChXjkOAQAA
X-Change-ID: 20251107-b4-m5441x-add-rng-support-0fdb8d40210a
To: Greg Ungerer <gerg@linux-m68k.org>, 
 Geert Uytterhoeven <geert@linux-m68k.org>, 
 Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Shawn Guo <shawnguo@kernel.org>, 
 Sascha Hauer <s.hauer@pengutronix.de>, 
 Pengutronix Kernel Team <kernel@pengutronix.de>, 
 Fabio Estevam <festevam@gmail.com>
Cc: linux-m68k@lists.linux-m68k.org, linux-kernel@vger.kernel.org, 
 linux-crypto@vger.kernel.org, imx@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, 
 Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.15-dev-47773
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764140889; l=1901;
 i=jeanmichel.hautbois@yoseli.org; s=20240925; h=from:subject:message-id;
 bh=spiyEbUBvIz19li1JaK2FG0GzYu6mQaFowCPaGoXONA=;
 b=KW1OEEH5eEn82WGsPE5ZXbQTMkHoI1HYZhvoS7o09XY0WJkpJ9ULWzrKgRcgEkFvCT+94hs9j
 vSPNjllFaowCsRDYquAgl7wx7FbXMkqEUoKtBdATzYqXrEjZg9RTll5
X-Developer-Key: i=jeanmichel.hautbois@yoseli.org; a=ed25519;
 pk=MsMTVmoV69wLIlSkHlFoACIMVNQFyvJzvsJSQsn/kq4=
X-Endpoint-Received: by B4 Relay for jeanmichel.hautbois@yoseli.org/20240925 with auth_id=570
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds support for the MCF54418 hardware random number generator
(RNGB).

The MCF54418 contains an RNGB hardware block compatible with the imx-rngc
driver. This series enables its use by:
- Adding platform device registration for the RNG hardware
- Enabling the clock at platform initialization
- Making the imx-rngc driver compatible with Coldfire's always-on clock
model using devm_clk_get_optional()

Testing on DLC Next board shows:
- Hardware RNG throughput: 26 MB/s
- FIPS 140-2 quality: 0.2% failure rate (rng-tools)
- Boot time improvement: CRNG initialization 7 seconds faster

Signed-off-by: Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>
---
Changes in v4:
- Postpone const qualifiers for now
- Link to v3: https://lore.kernel.org/r/20251124-b4-m5441x-add-rng-support-v3-0-f447251dad27@yoseli.org

Changes in v3:
- Depend on COLDFIRE is enough
- Split the clock change in a dedicated commit
- Link to v2: https://lore.kernel.org/r/20251107-b4-m5441x-add-rng-support-v2-0-f91d685832b9@yoseli.org

Changes in v2:
- Split const qualifier changes into a separate patch as suggested by
Frank Li
- Mark all resource arrays (including RNG) as const in device.c
- No functional changes to RNG implementation

---
Jean-Michel Hautbois (2):
      hwrng: imx-rngc: Use optional clock
      m68k: coldfire: Add RNG support for MCF54418

 arch/m68k/coldfire/device.c       | 28 ++++++++++++++++++++++++++++
 arch/m68k/coldfire/m5441x.c       |  2 +-
 arch/m68k/include/asm/m5441xsim.h |  9 +++++++++
 drivers/char/hw_random/Kconfig    |  3 ++-
 drivers/char/hw_random/imx-rngc.c |  9 ++++++++-
 5 files changed, 48 insertions(+), 3 deletions(-)
---
base-commit: ac3fd01e4c1efce8f2c054cdeb2ddd2fc0fb150d
change-id: 20251107-b4-m5441x-add-rng-support-0fdb8d40210a

Best regards,
--  
Jean-Michel Hautbois <jeanmichel.hautbois@yoseli.org>

