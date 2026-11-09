From: Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
Subject: [PATCH 0/2] iio: light: adux1020: fix proximity measurement issues
Date: Mon, 09 Nov 2026 11:39:01 +0000
Message-Id: <20261109-adux1020-measure-fixes-v1-0-fe1ba63f28bc@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMUQ6CMBCE4auQfXaTtiKCVzE+tDDVNQFN1xoSw
 t0t8vhl8s9CiiRQulQLJXxF5TUV2ENF/cNPd7AMxeSMa6w1Hfshz9Y4wyO85gSOMkO5i8cQ2rq
 O51NLJX4n/IfSXm+7NYcn+s/2Ruv6Az9WMdN6AAAA
X-Change-ID: 20261109-adux1020-measure-fixes-9f3bb844f758
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Manivannan Sadhasivam <mani@kernel.org>
Cc: linux@analog.com, linux-iio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794224343; l=1623;
 i=raffaele.tranfaglia@gmail.com; s=20261011; h=from:subject:message-id;
 bh=2Gdy8ztYs31P4MGi0uVjJ2HcIDHZ0VjZXsn3fGJQTSM=;
 b=W2E7lj03k+H/PAnWCUQnAZ+Li1H297foRYcibX1kSh9oLx7Jm0TvSRhfD4OARnkUKv1Byszmo
 LPL2pMjwUeHCwdnVKnHKo8DlZgty8nuw2f8PPJix4Li9ZWMEn8pIeyv
X-Developer-Key: i=raffaele.tranfaglia@gmail.com; a=ed25519;
 pk=mweuSGNM6vguCTdqa+aiHwMXdgk70suj2wolzCp6XGM=
X-Endpoint-Received: by B4 Relay for raffaele.tranfaglia@gmail.com/20261011 with auth_id=1160
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

While testing the guard() conversion of this driver with i2c-stub, I
found two issues in adux1020_measure().

Patch 1 fixes a real bug: the interrupt clear value is computed as
~u16, which integer promotion turns into 0xffffff0f. Plain I2C
adapters silently truncate it to 0xff0f, but SMBus-only adapters reject
it with -EINVAL, so every proximity read fails on them.

Patch 2 extracts the FIFO byte count with FIELD_GET(). The current code
compares the unshifted field against the packet size. Per the
datasheet, the FIFO only stores complete packets, so this does not
misbehave on a working device, hence no Fixes tag.

Tested on arm64 QEMU with i2c-stub (an SMBus-only adapter), lockdep and
UBSAN enabled, planting FIFO byte counts in INT_STATUS by hand:
- before: reads fail with -EINVAL
- patch 1: count 2 returns the planted sample; count 1 also returns it
  (issue fixed by patch 2); count 0 times out with -EIO
- patch 1+2: count 2 returns the sample; counts 1 and 0 time out with
  -EIO
No lockdep or UBSAN reports.

I prepared these patches with the help of an AI coding assistant, and
reviewed and tested them myself.

---
Raffaele Tranfaglia (2):
      iio: light: adux1020: fix interrupt clear value on SMBus-only adapters
      iio: light: adux1020: extract the FIFO byte count with FIELD_GET()

 drivers/iio/light/adux1020.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
---
base-commit: b70566610b48ba49dec636019da4d696db64b085
change-id: 20261109-adux1020-measure-fixes-9f3bb844f758

Best regards,
--  
Raffaele Tranfaglia <raffaele.tranfaglia@gmail.com>

