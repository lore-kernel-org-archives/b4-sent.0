From: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
Subject: [PATCH v2 0/3] iio: common: improve InvenSense sample timestamping
Date: Mon, 20 Jul 2026 12:38:31 +0200
Message-Id: <20260720-iio-common-inv-sensors-timestamp-rework-v2-0-aec31446809c@tdk.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKf6XWoC/42OwQ7CIBBEf6Xh7BporBpP/ofpAWGxawM0LFZN0
 3+X1nj3+JKZeTMJxkTI4lRNIuFITDEUqDeVMJ0ONwSyhUUt6708qAaIIpjofQxAYQTGwDExZPL
 IWfsBEj5j6kEbp7TUWkq3E2VtSOjotZou7Zf5cb2jycv8kuiIc0zv9cqoltzPevjbOiqQYJV2i
 PVRNsaes+23pSnaeZ4/2OIZa+4AAAA=
X-Change-ID: 20260715-iio-common-inv-sensors-timestamp-rework-acf1a0aa00f4
To: Jonathan Cameron <jic23@kernel.org>, 
 David Lechner <dlechner@baylibre.com>, 
 =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784543936; l=1928;
 i=jean-baptiste.maneyrol@tdk.com; s=20240923; h=from:subject:message-id;
 bh=tkxgU4aAbLqEyR/VxCM3e2NBV1wEpOg7XgcWPywgfQM=;
 b=GNHbJW3B9c7N862rAx0+sWsS4qrg2L614qtItRg8irO4tZtktI2kDK6Ipe/3o1lUvqMZ2+ozi
 PhM6rcNbIDRBhdCQLgETP6GaRePlH3CJ6cm1vx3UxcjNtrV7ACN2H2M
X-Developer-Key: i=jean-baptiste.maneyrol@tdk.com; a=ed25519;
 pk=bRqF1WYk0hR3qrnAithOLXSD0LvSu8DUd+quKLxCicI=
X-Endpoint-Received: by B4 Relay for jean-baptiste.maneyrol@tdk.com/20240923 with auth_id=218
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series improves the InvenSense timestamping mechanism for 2 cases:
when using watermark and for high frequency sampling.

Data arriving by batch because of FIFO watermark will now be all aligned
correctly with the interrupt timestamp and the chip period measurement
will use a minimal period of 20ms to ensure that system latency is
not preventing measurement when using high frequency sampling.

This was tested using inv_icm42600 driver when using maximum FIFO
watermark and when using 1kHz sampling frequency.

Signed-off-by: Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>
---
Changes in v2:
- Add a 1st patch to convert to kernel types.
- Rework following review suggestions.
- Following Sashiko fix delta_counter usage and handle case of
  timestamp overflowing last interrupt by using s64 type for new_period.
- Reword commit message for better timestamp alignement using Jonathan
  proposition.
- Link to v1: https://patch.msgid.link/20260717-iio-common-inv-sensors-timestamp-rework-v1-0-d1afee2805cd@tdk.com

To: Jonathan Cameron <jic23@kernel.org>
To: David Lechner <dlechner@baylibre.com>
To: Nuno Sá <nuno.sa@analog.com>
To: Andy Shevchenko <andy@kernel.org>
Cc: linux-iio@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Jean-Baptiste Maneyrol (3):
      iio: inv_sensors: convert to kernel types
      iio: inv_sensors: better timestamp alignment when using watermark
      iio: inv_sensors: improve period measurement by using a longer delay

 .../iio/common/inv_sensors/inv_sensors_timestamp.c | 109 +++++++++++----------
 include/linux/iio/common/inv_sensors_timestamp.h   |  40 ++++----
 2 files changed, 81 insertions(+), 68 deletions(-)
---
base-commit: aa58ecc73466d0cb8c418de98e2225490bf600e3
change-id: 20260715-iio-common-inv-sensors-timestamp-rework-acf1a0aa00f4

Best regards,
--  
Jean-Baptiste Maneyrol <jean-baptiste.maneyrol@tdk.com>

