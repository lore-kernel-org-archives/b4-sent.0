From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH 0/2] dfu: expand env references in dfu_alt_info, export
 kernel_addr_r_size
Date: Sun, 04 Oct 2026 22:48:24 +0200
Message-Id: <20261004-b4-dfu-alt-info-env-expand-v1-0-700eb0e54b61@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMSwqDMBAA0KvIrDsQ46fiVYqLmEx0ioySqAji3
 Y3t8m3eCZECU4Q2OyHQzpFnSchfGdjRyEDILhm00nWuVIl9ic5vaKYVWfyMJDvSsRhx2NTV2+i
 isJVvIAVLIM/HL/90f8et/5JdnxGu6wbjE5jGfgAAAA==
X-Change-ID: 20261004-b4-dfu-alt-info-env-expand-8657a233c5f8
To: u-boot@lists.u-boot-project.org, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Lukasz Majewski <lukma@denx.de>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Tom Rini <trini@konsulko.com>, Sean Anderson <sean.anderson@linux.dev>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Antony Kurniawan Soemardi <linux@smankusors.com>, 
 Petr Pavlata <petr@acrux.cz>, David Heidelberg <david@ixit.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791146915; l=1001;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=SeSaCm/2K8fRX/CYHdjFrFXfiD5aBGwC79FXh3F++Fk=;
 b=zZkb2OzRsf4psOGHs63bjaLzdXOKSPPjIQZBYibtBorKDUkibdoJ+QgUivVDN6Kc8Lysb/niF
 DFDX7OLu/jeAZ3o0/ZDdBr69wYMAqsIjuilonrxj2UloQbTySFP8Y/r
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

`dfu_alt_info` is read via env_get() which doesn't expand ${var}
references the way hush does on a command line. So any board wanting
to point a DFU alt at an existing buffer had to hardcode its address
and size separately instead of referencing the real env vars.

This adds the missing ${...} expansion in drivers/dfu/dfu.c and
exports kernel_addr_r_size alongside the existing kernel_addr_r on
Snapdragon so dfu_alt_info can reference it directly.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (2):
      dfu: expand ${...} env references in dfu_alt_info before parsing
      arm: snapdragon: export kernel_addr_r_size

 arch/arm/mach-snapdragon/board.c |  1 +
 drivers/dfu/dfu.c                | 16 +++++++++++++++-
 2 files changed, 16 insertions(+), 1 deletion(-)
---
base-commit: 71433ebf2aed1be5fbd2b1d497eae670ab9b9962
change-id: 20261004-b4-dfu-alt-info-env-expand-8657a233c5f8

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

