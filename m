From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH v2 0/2] iio_ frequency: adf4350: prescaler and register map
 fixes
Date: Fri, 29 Aug 2025 12:25:41 +0100
Message-Id: <20250829-adf4350-fix-v2-0-0bf543ba797d@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADaOsWgC/22MQQ7CIBAAv9LsWcwCJaWe/IfpgcK2JVEwYIim4
 e9izx5nkpkdMiVPGS7dDomKzz6GBuLUgd1MWIl51xgECoUaNTNu6aVCtvg3k4TzOA9W9gKhFc9
 ETR+329R48/kV0+eYF/6z/z+FM86UJnLK4iDVeDXB3ON6tvEBU631CwFtY8unAAAA
X-Change-ID: 20250808-adf4350-fix-3e0b9b7c3420
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1756466743; l=526;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=I9x5+JZP4lWupBgVDkivsnIqhBa0ffZvWtaGaAn8KY4=;
 b=CSm9UFnUNDt5dV/4rCYjFSxJ3fJL7DIN4oY6kiY3ndVZif4I6ZBof275VOwK/mKs2WwddgEy1
 n5ASdSyISY+DNhFHjZ9CoYe4+vStEMjd2FShUN2bAruhZajsY4HXVH5
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add some outstading fixes (that lived in ADI fork) for the ad4350 fixes.

---
Michael Hennerich (2):
      iio: frequency: adf4350: Fix prescaler usage.
      iio: frequency: adf4350: Fix ADF4350_REG3_12BIT_CLKDIV_MODE

 drivers/iio/frequency/adf4350.c       | 20 +++++++++++++-------
 include/linux/iio/frequency/adf4350.h |  2 +-
 2 files changed, 14 insertions(+), 8 deletions(-)
---
base-commit: 6408dba154079656d069a6a25fb3a8954959474c
change-id: 20250808-adf4350-fix-3e0b9b7c3420
--

Thanks!
- Nuno Sá

