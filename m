From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Subject: [PATCH 0/9] iio: replace sprintf() with sysfs_emit() in
 .read_label() op
Date: Tue, 30 Sep 2025 16:33:09 +0100
Message-Id: <20250930-dev-sprintf-cleanup-v1-0-5d65d096a952@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIADX422gC/x3MTQqAIBBA4avIrBsw+yG7SrQwG2sgTLQiiO6et
 PwW7z2QKDIl6MUDkS5OvPuMshBgV+MXQp6zQUnVSF1JnOnCFCL7w6HdyPgz4GScsp2eqrqVkMs
 QyfH9X4fxfT8l4ggaZQAAAA==
X-Change-ID: 20250930-dev-sprintf-cleanup-baf2c89b3460
To: linux-iio@vger.kernel.org
Cc: Michael Hennerich <Michael.Hennerich@analog.com>, 
 Esteban Blanc <eblanc@baylibre.com>, Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, Andy Shevchenko <andy@kernel.org>, 
 Marius Cristea <marius.cristea@microchip.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Matteo Martelli <matteomartelli3@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Srinivas Pandruvada <srinivas.pandruvada@linux.intel.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sal@analog.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1759246391; l=1637;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Ujr3vQFuXMf6tuVm3oUvumgJUXtr5UkQ7zY3FbabcwE=;
 b=8di7Bmh4STjVso35xo+9KoFdUYG/3kFvDlxCfrbNPZczY3HcMa1qMINHkm+pDpUfvfts8bioc
 0vUbXM82UdlCHOphjbqnfS1Pl5XtiZPD7W+NHWks0UvNAHjLFN35Mu9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When looking at some drivers implementing the .read_label() callback it
came to my attention that there were some outliers using sprintf() (or
even snprintf() with PAGE_SIZE) instead of sysfs_emit(). This series
cleans that up. 

---
Nuno Sá (9):
      iio: adc: ad4030: replace sprintf() with sysfs_emit()
      iio: adc: ad7768-1: replace sprintf() with sysfs_emit()
      iio: adc: mcp3564: replace sprintf() with sysfs_emit()
      iio: adc: meson_saradc: replace sprintf() with sysfs_emit()
      iio: adc: mt6360-adc: replace snprintf() with sysfs_emit()
      iio: adc: pac1921: replace sprintf() with sysfs_emit()
      iio: adc: qcom-spmi-rradc: replace snprintf() with sysfs_emit()
      iio: position: hid-sensor-custom-intel-hinge: replace sprintf() with sysfs_emit()
      iio: resolver: ad2s1210: replace sprintf() with sysfs_emit()

 drivers/iio/adc/ad4030.c                           |  4 +--
 drivers/iio/adc/ad7768-1.c                         |  2 +-
 drivers/iio/adc/mcp3564.c                          |  2 +-
 drivers/iio/adc/meson_saradc.c                     |  6 ++---
 drivers/iio/adc/mt6360-adc.c                       |  2 +-
 drivers/iio/adc/pac1921.c                          |  8 +++---
 drivers/iio/adc/qcom-spmi-rradc.c                  |  2 +-
 .../iio/position/hid-sensor-custom-intel-hinge.c   |  2 +-
 drivers/iio/resolver/ad2s1210.c                    | 30 +++++++++++-----------
 9 files changed, 29 insertions(+), 29 deletions(-)
---
base-commit: b9700f87939f0f477e5c00db817f54ab8a97702b
change-id: 20250930-dev-sprintf-cleanup-baf2c89b3460
--

Thanks!
- Nuno Sá

