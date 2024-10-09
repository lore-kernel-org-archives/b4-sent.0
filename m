From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/4] iio: frequecy: adf4371: minor improvements
Date: Wed, 09 Oct 2024 16:16:42 +0200
Message-Id: <20241009-dev-adf4371-minor-improv-v1-0-97f4f22ed941@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAEqQBmcC/x3MMQqAMBAF0avI1i4kKopeRSyC+eoWJrKBIIh3N
 1i+YuahBBUkmqqHFFmSxFBg64rWw4UdLL6YGtN01piRPTI7v3XtYPmUEJXlvDRmxgD0Dq5FDyr
 5pdjk/tfz8r4fwm/O1moAAAA=
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1728483403; l=596;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=6iYbHzhTYiF+evAJ/CrJLAYhxN+1XjEyn9X2cWlcS28=;
 b=xHENApoV7M48S6XGMBjcpMZNwuXrocUYu6KUpxcM4YCR94O+M3onSFBoQELNYuadNzIkP7Hs1
 7aklNfcZTbrARy152RUwLB/NSGtLmPq7cSIJzDeTUAfxiQRt366GPbo
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Just some simple and minor cleanups.

---
Nuno Sa (4):
      iio: frequency: adf4371: make use of spi_get_device_match_data()
      iio: frequency: adf4371: drop spi_set_drvdata()
      iio: frequency: adf4371: drop clkin from struct adf4371_state
      iio: frequency: adf4371: make use of dev_err_probe()

 drivers/iio/frequency/adf4371.c | 63 +++++++++++++++++++++--------------------
 1 file changed, 32 insertions(+), 31 deletions(-)
---
base-commit: 96be67caa0f0420d4128cb67f07bbd7a6f49e03a
change-id: 20241009-dev-adf4371-minor-improv-e7ee6aea3e6e
--

Thanks!
- Nuno Sá

