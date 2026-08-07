From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Fri, 07 Aug 2026 12:26:11 +0100
Subject: [PATCH 4/4] char: tpm: use named initializers for acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-acpi-char-v1-4-742c450254dd@thegoodpenguin.co.uk>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786101977; l=4406;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=/3HqANNdgwc+v+bCM8pvoBxFH0K5Gv93E5IVVo98Axg=;
 b=tf+58qMPqBQXxvk2WPfC/OQEoHIfmkXD63JrsmKQeLQrAB7+MHX/CG+u3PeHojtQrguurPS92
 ZI4sHrI8wo+AOM+l+bNQmPulehYsu90b6a0bz8vi4w9YyUXFRQ6bsUD
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
 drivers/char/tpm/st33zp24/i2c.c      | 4 ++--
 drivers/char/tpm/st33zp24/spi.c      | 4 ++--
 drivers/char/tpm/tpm_crb.c           | 4 ++--
 drivers/char/tpm/tpm_tis.c           | 4 ++--
 drivers/char/tpm/tpm_tis_i2c_cr50.c  | 4 ++--
 drivers/char/tpm/tpm_tis_spi_main.c  | 4 ++--
 drivers/char/tpm/tpm_tis_synquacer.c | 4 ++--
 7 files changed, 14 insertions(+), 14 deletions(-)

diff --git a/drivers/char/tpm/st33zp24/i2c.c b/drivers/char/tpm/st33zp24/i2c.c
index 81348487c125..d2bf9996760d 100644
--- a/drivers/char/tpm/st33zp24/i2c.c
+++ b/drivers/char/tpm/st33zp24/i2c.c
@@ -145,8 +145,8 @@ static const struct of_device_id of_st33zp24_i2c_match[] __maybe_unused = {
 MODULE_DEVICE_TABLE(of, of_st33zp24_i2c_match);
 
 static const struct acpi_device_id st33zp24_i2c_acpi_match[] __maybe_unused = {
-	{"SMO3324"},
-	{}
+	{ .id = "SMO3324" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, st33zp24_i2c_acpi_match);
 
diff --git a/drivers/char/tpm/st33zp24/spi.c b/drivers/char/tpm/st33zp24/spi.c
index 5149231f3de2..6671977c44aa 100644
--- a/drivers/char/tpm/st33zp24/spi.c
+++ b/drivers/char/tpm/st33zp24/spi.c
@@ -262,8 +262,8 @@ static const struct of_device_id of_st33zp24_spi_match[] __maybe_unused = {
 MODULE_DEVICE_TABLE(of, of_st33zp24_spi_match);
 
 static const struct acpi_device_id st33zp24_spi_acpi_match[] __maybe_unused = {
-	{"SMO3324"},
-	{}
+	{ .id = "SMO3324" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, st33zp24_spi_acpi_match);
 
diff --git a/drivers/char/tpm/tpm_crb.c b/drivers/char/tpm/tpm_crb.c
index ceb4100ba400..671ba480a675 100644
--- a/drivers/char/tpm/tpm_crb.c
+++ b/drivers/char/tpm/tpm_crb.c
@@ -917,8 +917,8 @@ static const struct dev_pm_ops crb_pm = {
 };
 
 static const struct acpi_device_id crb_device_ids[] = {
-	{"MSFT0101", 0},
-	{"", 0},
+	{ .id = "MSFT0101" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, crb_device_ids);
 
diff --git a/drivers/char/tpm/tpm_tis.c b/drivers/char/tpm/tpm_tis.c
index 9aa230a63616..4bb18fb1df87 100644
--- a/drivers/char/tpm/tpm_tis.c
+++ b/drivers/char/tpm/tpm_tis.c
@@ -130,8 +130,8 @@ static inline int is_itpm(struct acpi_device *dev)
 #define DEVICE_IS_TPM2 1
 
 static const struct acpi_device_id tpm_acpi_tbl[] = {
-	{"MSFT0101", DEVICE_IS_TPM2},
-	{},
+	{ .id = "MSFT0101", .driver_data = DEVICE_IS_TPM2 },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, tpm_acpi_tbl);
 
diff --git a/drivers/char/tpm/tpm_tis_i2c_cr50.c b/drivers/char/tpm/tpm_tis_i2c_cr50.c
index b48cacacc066..dc8a5ec5799b 100644
--- a/drivers/char/tpm/tpm_tis_i2c_cr50.c
+++ b/drivers/char/tpm/tpm_tis_i2c_cr50.c
@@ -669,8 +669,8 @@ static const struct tpm_class_ops cr50_i2c = {
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id cr50_i2c_acpi_id[] = {
-	{ "GOOG0005", 0 },
-	{}
+	{ .id = "GOOG0005" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, cr50_i2c_acpi_id);
 #endif
diff --git a/drivers/char/tpm/tpm_tis_spi_main.c b/drivers/char/tpm/tpm_tis_spi_main.c
index 61b42c83ced8..d2e37e667dd7 100644
--- a/drivers/char/tpm/tpm_tis_spi_main.c
+++ b/drivers/char/tpm/tpm_tis_spi_main.c
@@ -339,8 +339,8 @@ static const struct of_device_id of_tis_spi_match[] __maybe_unused = {
 MODULE_DEVICE_TABLE(of, of_tis_spi_match);
 
 static const struct acpi_device_id acpi_tis_spi_match[] __maybe_unused = {
-	{"SMO0768", 0},
-	{}
+	{ .id = "SMO0768" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, acpi_tis_spi_match);
 
diff --git a/drivers/char/tpm/tpm_tis_synquacer.c b/drivers/char/tpm/tpm_tis_synquacer.c
index 4927714d277a..c2d09315aa17 100644
--- a/drivers/char/tpm/tpm_tis_synquacer.c
+++ b/drivers/char/tpm/tpm_tis_synquacer.c
@@ -144,8 +144,8 @@ MODULE_DEVICE_TABLE(of, tis_synquacer_of_platform_match);
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id tpm_synquacer_acpi_tbl[] = {
-	{ "SCX0009" },
-	{},
+	{ .id = "SCX0009" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, tpm_synquacer_acpi_tbl);
 #endif

-- 
2.55.0

