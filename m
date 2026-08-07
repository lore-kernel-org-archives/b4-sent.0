From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Fri, 07 Aug 2026 12:26:09 +0100
Subject: [PATCH 2/4] char: hw_random: use named initializers for
 acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-acpi-char-v1-2-742c450254dd@thegoodpenguin.co.uk>
References: <20260807-acpi-char-v1-0-742c450254dd@thegoodpenguin.co.uk>
In-Reply-To: <20260807-acpi-char-v1-0-742c450254dd@thegoodpenguin.co.uk>
To: Clemens Ladisch <clemens@ladisch.de>, Arnd Bergmann <arnd@arndb.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Mattia Dongili <malattia@linux.it>, Weili Qian <qianweili@huawei.com>, 
 Olivia Mackall <olivia@selenic.com>, 
 Herbert Xu <herbert@gondor.apana.org.au>, Corey Minyard <corey@minyard.net>, 
 Peter Huewe <peterhuewe@gmx.de>, Jarkko Sakkinen <jarkko@kernel.org>, 
 Jason Gunthorpe <jgg@ziepe.ca>
Cc: linux-kernel@vger.kernel.org, platform-driver-x86@vger.kernel.org, 
 linux-crypto@vger.kernel.org, openipmi-developer@lists.sourceforge.net, 
 linux-integrity@vger.kernel.org, 
 "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786101977; l=1444;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=+xP/DyVMe1G4+tAB3K0pNQD1hmkjHQX41ImGXQMTrqo=;
 b=0HUTmx5EbpEP+CnAz7BzmRJIaxcloUiHZXMfz0ArQH/ota00MUtfLnrJJ+ZIOOqQOvhZmYEbW
 0f34qLnp+dkBj5v+DUifGCk+mk1l3vixpU0WqVISP8BfnsFy3ocKq5F
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a named initializer for the acpi_device_id fields which
makes the code more readable and consistent with how lists
are initialized in the rest of the kernel code base. Also
drop explicitly setting fields to 0 where it is redundant.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
 drivers/char/hw_random/hisi-trng-v2.c | 2 +-
 drivers/char/hw_random/xgene-rng.c    | 2 +-
 2 files changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/char/hw_random/hisi-trng-v2.c b/drivers/char/hw_random/hisi-trng-v2.c
index 6584ed051e09..9e0ecea56ad6 100644
--- a/drivers/char/hw_random/hisi-trng-v2.c
+++ b/drivers/char/hw_random/hisi-trng-v2.c
@@ -77,7 +77,7 @@ static int hisi_trng_probe(struct platform_device *pdev)
 }
 
 static const struct acpi_device_id hisi_trng_acpi_match[] = {
-	{ "HISI02B3", 0 },
+	{ .id = "HISI02B3" },
 	{ }
 };
 MODULE_DEVICE_TABLE(acpi, hisi_trng_acpi_match);
diff --git a/drivers/char/hw_random/xgene-rng.c b/drivers/char/hw_random/xgene-rng.c
index 1f4b95341c2e..222db3fb275b 100644
--- a/drivers/char/hw_random/xgene-rng.c
+++ b/drivers/char/hw_random/xgene-rng.c
@@ -296,7 +296,7 @@ static int xgene_rng_init(struct hwrng *rng)
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id xgene_rng_acpi_match[] = {
-	{ "APMC0D18", },
+	{ .id = "APMC0D18" },
 	{ }
 };
 MODULE_DEVICE_TABLE(acpi, xgene_rng_acpi_match);

-- 
2.55.0

