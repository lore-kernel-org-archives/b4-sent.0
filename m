From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Fri, 07 Aug 2026 12:26:08 +0100
Subject: [PATCH 1/4] char: use named initializers for acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-acpi-char-v1-1-742c450254dd@thegoodpenguin.co.uk>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786101977; l=1438;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=pvB6ZcDxtCyp+EzKE8EtX3iLA867vIHnUjBmQtM3fso=;
 b=YTbY0Byzh9twQPYPaHqXd78e8yC5EkKfcmlK50U7O+CtoiLA+mqwdKP+rCxcm/KFXqjUONHwc
 5ttc+Vh3y7DDUljM+RW9A8CCTSGLrzvi/Eb1j0ysFpNwPIJOOL35IUN
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Use a named initializer for the acpi_device_id fields which
makes the code more readable and consistent with how lists
are initialized in the rest of the kernel code base. Also
drop explicitly setting fields to 0 where it is redundant.

While we are at it - unify the list terminator to have
a single space between the brackets and no trailing
comma.

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
 drivers/char/hpet.c   | 4 ++--
 drivers/char/sonypi.c | 4 ++--
 2 files changed, 4 insertions(+), 4 deletions(-)

diff --git a/drivers/char/hpet.c b/drivers/char/hpet.c
index 285c6037417a..88d0d4750a6b 100644
--- a/drivers/char/hpet.c
+++ b/drivers/char/hpet.c
@@ -1004,8 +1004,8 @@ static int hpet_acpi_probe(struct platform_device *pdev)
 }
 
 static const struct acpi_device_id hpet_device_ids[] = {
-	{"PNP0103", 0},
-	{"", 0},
+	{ .id = "PNP0103" },
+	{ }
 };
 
 static struct platform_driver hpet_acpi_driver = {
diff --git a/drivers/char/sonypi.c b/drivers/char/sonypi.c
index 9309cfb935be..fb6357ba69dc 100644
--- a/drivers/char/sonypi.c
+++ b/drivers/char/sonypi.c
@@ -1136,8 +1136,8 @@ static void sonypi_acpi_remove(struct platform_device *pdev)
 }
 
 static const struct acpi_device_id sonypi_device_ids[] = {
-	{"SNY6001", 0},
-	{"", 0},
+	{ .id = "SNY6001" },
+	{ }
 };
 
 static struct platform_driver sonypi_acpi_driver = {

-- 
2.55.0

