From: "Pawel Zalewski (The Capable Hub)" <pzalewski@thegoodpenguin.co.uk>
Subject: [PATCH 0/4] char: use named initializers for acpi_device_id
Date: Fri, 07 Aug 2026 12:26:07 +0100
Message-Id: <20260807-acpi-char-v1-0-742c450254dd@thegoodpenguin.co.uk>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqAIBCF4avIrBNMS6KrRAu1qaZFiVYE0t2zW
 n68x58gYiCM0LIEAU+KtK0ZZcHAzWadkNOQDVJILRpRceM88TwFXmtVamOlHYSC/PcBR7q+Vtf
 /jodd0O1vAO77ATA9ONZtAAAA
X-Change-ID: 20260804-acpi-char-56316ab2bd03
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786101977; l=2628;
 i=pzalewski@thegoodpenguin.co.uk; s=20260803; h=from:subject:message-id;
 bh=5YH4OupiPVo5NYgT2GzQ1B//oZTWncXO4yg7L+WC4DY=;
 b=NA9cF3yI3G/BlKzZxVpLLEfNwbAVtxJvSfEditTvaz3eLv9d9F76mjHh+vdh51KaaXZBAOBBk
 pz0pPkhM/RMCL1CtormNODpEEEv98rEcOhrjklgX0piQSVvDX/KXx4q
X-Developer-Key: i=pzalewski@thegoodpenguin.co.uk; a=ed25519;
 pk=W3zk1cb/wRnj6pNGbl3/2Zf3GmPA6IBpNHpDPyJ05k8=
X-Endpoint-Received: by B4 Relay for pzalewski@thegoodpenguin.co.uk/20260803 with auth_id=913
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series is converting lists that contain the acpi_device_id
struct, which is defined in the include/linux/device-id/acpi.h
to makes use of named initializers (which they do not use currently).
This work is part of the on going effort in the kernel associated
with device-ids [1]

The plan is to convert acpi_device_id::driver_data to have an anonymous
union, similarly to what was introduced for PCI and I2C device ID tables.
The goal is to increase type-safety (as most of the existing casts are gone),
to improve readability and to make use intent a bit more clear:

```
union {
	kernel_ulong_t driver_data;
	const void *driver_data_ptr;
}
```

But for that to work all lists containing the structs need to use named
initializers first. I already have patches that implement this and touching
a lot of kernel subsystmes that use the acpi_device_id struct and that list
keeps on growing. Therefore, I have decided to split the series per every
subsystem into:
- pre-clean-ups that convert the lists to use named initializers (this series)
- actual implementations that make some of the modules use the new driver_data_ptr

That way the task can be fragmented into manageable and independent
chunks of work and makes this effort easier to review.

Tested builds on a64 in Yocto using 7.2-rc6

Signed-off-by: Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>
---
Pawel Zalewski (The Capable Hub) (4):
      char: use named initializers for acpi_device_id
      char: hw_random: use named initializers for acpi_device_id
      char: ipmi: use named initializers for acpi_device_id
      char: tpm: use named initializers for acpi_device_id

 drivers/char/hpet.c                   | 4 ++--
 drivers/char/hw_random/hisi-trng-v2.c | 2 +-
 drivers/char/hw_random/xgene-rng.c    | 2 +-
 drivers/char/ipmi/ipmb_dev_int.c      | 4 ++--
 drivers/char/ipmi/ipmi_si_platform.c  | 4 ++--
 drivers/char/ipmi/ipmi_ssif.c         | 4 ++--
 drivers/char/sonypi.c                 | 4 ++--
 drivers/char/tpm/st33zp24/i2c.c       | 4 ++--
 drivers/char/tpm/st33zp24/spi.c       | 4 ++--
 drivers/char/tpm/tpm_crb.c            | 4 ++--
 drivers/char/tpm/tpm_tis.c            | 4 ++--
 drivers/char/tpm/tpm_tis_i2c_cr50.c   | 4 ++--
 drivers/char/tpm/tpm_tis_spi_main.c   | 4 ++--
 drivers/char/tpm/tpm_tis_synquacer.c  | 4 ++--
 14 files changed, 26 insertions(+), 26 deletions(-)
---
base-commit: 848acc8ffe1b7cd5f1bf427b93069becfebc2c9d
change-id: 20260804-acpi-char-56316ab2bd03

Best regards,
--  
Pawel Zalewski (The Capable Hub) <pzalewski@thegoodpenguin.co.uk>

