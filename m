From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/4] spi: xcomm: support GPO pin
Date: Fri, 05 Jul 2024 17:12:38 +0200
Message-Id: <20240705-dev-spi-xcomm-gpiochip-v2-0-b10842fc9636@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAGYNiGYC/x3MTQqAIBBA4avIrBtQEfq5SrQInWoW5aAgQnj3p
 OW3eO+FTIkpw6JeSFQ4c3w67KDAX/tzEnLoBqut06N2GKhgFsbq433jKRz9xYKTMc7P0+wOPUK
 PJdHB9R+vW2sfKeDC4WgAAAA=
To: linux-spi@vger.kernel.org
Cc: Mark Brown <broonie@kernel.org>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Michael Hennerich <michael.hennerich@analog.com>
X-Mailer: b4 0.14.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720192365; l=690;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=YsQxoqRb0qm/DMyEY5p3KivTlb4LK+jdMPeUhUZ8Q+8=;
 b=hRo5JyF/I8Qao5LUJV5XUlrBeaiBcWKxlX7Z9yZHZuNoD1mOI2MXulRPFcaXNWWFJbc2f8A4N
 /VrRGlHbhV3CTeD2Dl7M9lZ0J5vZJy18GLtKjSj9ZE3v/hEPRHTkWFX
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Here it goes v2 without get() support.

v1
 * https://lore.kernel.org/linux-spi/20240704-dev-spi-xcomm-gpiochip-v1-0-653db6fbef36@analog.com/

v2
 * Remove get() from gpiochip ops.

---
Michael Hennerich (1):
      spi: xcomm: add gpiochip support

Nuno Sa (3):
      spi: xcomm: make use of devm_spi_alloc_host()
      spi: xcomm: remove i2c_set_clientdata()
      spi: xcomm: fix coding style

 drivers/spi/spi-xcomm.c | 75 +++++++++++++++++++++++++++++++++++++------------
 1 file changed, 57 insertions(+), 18 deletions(-)
---
base-commit: 56b6e631686eacbaf1970043027aadafea2b8438
change-id: 20240704-dev-spi-xcomm-gpiochip-8114c9894f07
--

Thanks!
- Nuno Sá

