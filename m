From: Fil Dunsky <filipp.dunsky@gmail.com>
Subject: [PATCH v2 0/3] hwrng: Add Cortina Systems CS7542 random number
 generator
Date: Tue, 24 Nov 2026 11:20:18 +0300
Message-Id: <20261124-b4-cs7542-trng-v2-0-0192937b44be@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CQAxFr0K6toYW0Iwr72FYwNCBGmHMDBIN4
 e4Crl2+5P33Z4gSVCJckhmCTBrVDyvwIQHbVUMrqM3KwCmfiDjDOkcbz0XOOIahRaqoNo5skxm
 GdfQM4vS9B2/lj+Orvosdt8pmdBpHHz7740Sb9zc+EaZouDHOWZEio2vbV/o4Wt9DuSzLF42tz
 Ue+AAAA
X-Change-ID: 20261123-b4-cs7542-trng-1a1b9f1cd392
To: Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: =?utf-8?q?Uwe_Kleine-K=C3=B6nig?= <u.kleine-koenig@baylibre.com>, 
 linux-crypto@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795508418; l=3072;
 i=filipp.dunsky@gmail.com; s=20260930; h=from:subject:message-id;
 bh=cxbkSaTDthKEwcdkWgVbloUCaiiY0AcMv8pFTjp9QIY=;
 b=53TlVVtccxEE5Rny7rrzitIWySScAbfYdvVN7aGSCRuTe/5xfYgQIYtLG3Y1kv4pLedC+Kun+
 xn2+1/utxFuCpHLs4nFGqyItpLVt+eLQie7bqurJ7vgqJXOInDPxtSY
X-Developer-Key: i=filipp.dunsky@gmail.com; a=ed25519;
 pk=JAYP8e2rJ54DHOmhNtXud8rl1igAaAXoOHxtJmVXI1g=
X-Endpoint-Received: by B4 Relay for filipp.dunsky@gmail.com/20260930 with auth_id=1085
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the Elliptic random number generator integrated in the CS7542,
based on the GPL vendor and OpenWrt implementations. Use a syscon
regmap for its shared global scratch bit and provide bounded polling,
nonblocking pending requests and partial output through the hwrng core.

Hardware ring reseeding is limited to the documented CS7542 A1 path.
The vendor driver avoids it on A0 for erratum 28891 and substitutes a
RTC/timer-derived nonce. Reject unsupported revisions using the global
syscon identification register instead of adopting that workaround.
The saved Almond+ capture identifies the tested board as CS7542 A1.

The binding, driver and MAINTAINERS entry apply to Linux v7.4-rc4
without the pending CS75xx platform or clock/pinctrl series.

The existing OpenWrt entropy quality setting of 512 is retained for
review. The output smoke tests do not establish an entropy estimate.

The v1 sources passed binding/example checks, ARM built-in and module
builds and RAM hardware smoke tests on Almond+. The hardware test
returned EAGAIN for the first nonblocking read, then provided 4096
bytes without all-zero or repeated-block output.

No additional hardware run is claimed for v2. The generating path on
A1 is unchanged; revision checks and their error paths were tested
with the actual C code and mocked resource/regmap/hwrng interfaces.
Full ARM W=1 built-in and module builds were repeated for v2.

---
Changes in v2:
- Drop the redundant linux/mod_devicetable.h include as suggested by
  Uwe Kleine-König. The existing linux/of.h provides the OF device ID.
- Restrict hardware reseeding to CS7542 A1 after inspecting the vendor
  erratum 28891 workaround. Propagate revision-read failures and reject
  unsupported silicon before registering the hwrng.
- Describe the hardware revision restriction and identification register
  in the binding.
- Link to v1: https://lore.kernel.org/all/20261123-b4-cs7542-trng-v1-0-92d9ffcee531@gmail.com/

To: Fil Dunsky <filipp.dunsky@gmail.com>
To: Olivia Mackall <olivia@selenic.com>
To: Herbert Xu <herbert@gondor.apana.org.au>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
Cc: linux-crypto@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Fil Dunsky (3):
      dt-bindings: rng: Add Cortina Systems CS7542 TRNG
      hwrng: Add Cortina Systems CS7542 TRNG driver
      MAINTAINERS: Add Cortina Systems CS7542 TRNG support

 .../bindings/rng/cortina,cs7542-trng.yaml          |  43 +++++
 MAINTAINERS                                        |   7 +
 drivers/char/hw_random/Kconfig                     |  11 ++
 drivers/char/hw_random/Makefile                    |   1 +
 drivers/char/hw_random/cs75xx-trng.c               | 187 +++++++++++++++++++++
 5 files changed, 249 insertions(+)
---
base-commit: b6a9fa34ce4187cb69d3c588a4bbffc31ce5db8f
change-id: 20261123-b4-cs7542-trng-1a1b9f1cd392

Best regards,
--  
Fil Dunsky <filipp.dunsky@gmail.com>

