From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Date: Fri, 07 Aug 2026 12:26:10 +0100
Subject: [PATCH 3/4] char: ipmi: use named initializers for acpi_device_id
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260807-acpi-char-v1-3-742c450254dd@thegoodpenguin.co.uk>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786101977; l=2063;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=KSRiDBr/KlyRDt2jepviaq+isDgvIHWz0zDwNFdjAOU=;
 b=bCJjHt/hyxm30i2BmzMj5Gp85SGiXlRWj3FSLgnvW2M2kAKEaM/kJIXMgIHKiz9Yg6JcxhmDj
 GMofNtEZ1cuBR5rNsqrIDtpnm5s7KCQGSJMAUcw6cnNwkzQ0hTvgOVy
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
 drivers/char/ipmi/ipmb_dev_int.c     | 4 ++--
 drivers/char/ipmi/ipmi_si_platform.c | 4 ++--
 drivers/char/ipmi/ipmi_ssif.c        | 4 ++--
 3 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/drivers/char/ipmi/ipmb_dev_int.c b/drivers/char/ipmi/ipmb_dev_int.c
index 680ff15c30ab..d576a77df927 100644
--- a/drivers/char/ipmi/ipmb_dev_int.c
+++ b/drivers/char/ipmi/ipmb_dev_int.c
@@ -360,8 +360,8 @@ MODULE_DEVICE_TABLE(i2c, ipmb_id);
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id acpi_ipmb_id[] = {
-	{ "IPMB0001", 0 },
-	{},
+	{ .id = "IPMB0001" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, acpi_ipmb_id);
 #endif
diff --git a/drivers/char/ipmi/ipmi_si_platform.c b/drivers/char/ipmi/ipmi_si_platform.c
index bdc481ce1302..fa221cbb4b3b 100644
--- a/drivers/char/ipmi/ipmi_si_platform.c
+++ b/drivers/char/ipmi/ipmi_si_platform.c
@@ -387,8 +387,8 @@ static int acpi_ipmi_probe(struct platform_device *pdev)
 }
 
 static const struct acpi_device_id acpi_ipmi_match[] = {
-	{ "IPI0001", 0 },
-	{ },
+	{ .id = "IPI0001" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, acpi_ipmi_match);
 #else
diff --git a/drivers/char/ipmi/ipmi_ssif.c b/drivers/char/ipmi/ipmi_ssif.c
index 07f1d2327bb7..2361103c5edc 100644
--- a/drivers/char/ipmi/ipmi_ssif.c
+++ b/drivers/char/ipmi/ipmi_ssif.c
@@ -2057,8 +2057,8 @@ static unsigned short *ssif_address_list(void)
 
 #ifdef CONFIG_ACPI
 static const struct acpi_device_id ssif_acpi_match[] = {
-	{ "IPI0001", 0 },
-	{ },
+	{ .id = "IPI0001" },
+	{ }
 };
 MODULE_DEVICE_TABLE(acpi, ssif_acpi_match);
 #endif

-- 
2.55.0

