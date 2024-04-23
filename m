From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/4] dev_printk: add dev_errp_probe() helper
Date: Tue, 23 Apr 2024 17:20:29 +0200
Message-Id: <20240423-dev-add_dev_errp_probe-v2-0-12f43c5d8b0d@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAL3RJ2YC/x2MQQqAIBAAvxJ7TjAzgr4SIdZutReVFSIQ/550G
 uYwUyCTMGVYugJCD2eOoYnpOzhuHy5SjM3BaGO1NaNCepRHdI2ORJJLEndSA6K20zye1k/Q4iR
 08vuP163WDyo3lnloAAAA
To: Petr Mladek <pmladek@suse.com>, 
 Andy Shevchenko <andriy.shevchenko@linux.intel.com>, 
 Chris Down <chris@chrisdown.name>, John Ogness <john.ogness@linutronix.de>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jonathan Cameron <jic23@kernel.org>, Lars-Peter Clausen <lars@metafoo.de>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Andi Shyti <andi.shyti@kernel.org>, Jyoti Bhayana <jbhayana@google.com>
Cc: linux-kernel@vger.kernel.org, linux-iio@vger.kernel.org, 
 Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1713885641; l=1190;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=OyvbrdsdOf2HxYi0DXyL+Wx579OMeT8jr9c640c8pY4=;
 b=41tRg6ufy5pwxxCdDpPaKGvcgOMYRhybemdpQjZ2/Fd1w219f0pYfxPZNYkVdRLz/hQG2fDR5
 SWNbzCJuCvYCvKJVNHX+MCFghLuwPPD0itHC517e+02X/5N33+emX0k
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Here it goes the second version of this. Main difference is the
introduction of dev_err_cast_probe(). Full log:

v1:
 * https://lore.kernel.org/all/20240404-dev-add_dev_errp_probe-v1-0-d18e3eb7ec3f@analog.com/

v2:
 * Patch 1:
   - Renamed dev_errp_probe() -> dev_err_ptr_probe();
   - Added dev_err_cast_probe().
 * Patch 2:
   - Make use of dev_err_cast_probe();
   - Also use dev_err_ptr_probe() in __ltc2983_custom_sensor_new().  
 * Patch 3:
   - Use dev_err_cast_probe().

---
Nuno Sa (4):
      dev_printk: add new dev_err_probe() helpers
      iio: temperature: ltc2983: convert to dev_err_probe()
      iio: backend: make use of dev_err_cast_probe()
      iio: common: scmi_iio: convert to dev_err_probe()

 drivers/iio/common/scmi_sensors/scmi_iio.c |  45 ++---
 drivers/iio/industrialio-backend.c         |   8 +-
 drivers/iio/temperature/ltc2983.c          | 282 +++++++++++++----------------
 include/linux/dev_printk.h                 |   9 +
 4 files changed, 158 insertions(+), 186 deletions(-)
---
base-commit: a59668a9397e7245b26e9be85d23f242ff757ae8
change-id: 20240423-dev-add_dev_errp_probe-1dd04573f4a5
--

Thanks!
- Nuno Sá

