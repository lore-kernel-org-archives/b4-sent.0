From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/4] iio: imu: drop #ifdef around CONFIG_DEBUG_FS
Date: Fri, 09 Aug 2024 11:17:05 +0200
Message-Id: <20240809-dev-adis-debugfs-improv-v1-0-d3adb6996518@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAJHetWYC/x2MSQqAMAwAvyI5G4jF/SviQW1ac3ChwSKIf7d4m
 znMPKAchBX67IHAUVSOPUmRZ7Cs0+4ZxSYHQ6akljq0HHGyognmyztF2c5wRGSipmq6uTK1gVS
 fgZ3c/3kY3/cDhkHfHmkAAAA=
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723195072; l=860;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=nM1XhDBT2YBFAoOcyi44cvXhc/mFm7v09j5HLSuGW40=;
 b=JxszYtrjNT5amQMOEQmdVDKK7txdVB8/CHbVp5fbpXQ6c9Us9aCBjN+JDSAi+e633buajXk98
 5nqkgqx+pdYA1YxMcwieAJC4PZyCRRSM2RUfolJ5p5ia1vvlY3MtE98
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi,

Small series to make the IMUs debugfs code a bit neater. As mentioned in
the commit message, let's allow the compiler to drop any unused instead
of guarding it with #ifdefs.

---
Nuno Sa (4):
      iio: imu: adis16475: drop ifdef around CONFIG_DEBUG_FS
      iio: imu: adis16480: drop ifdef around CONFIG_DEBUG_FS
      iio: imu: adis16400: drop ifdef around CONFIG_DEBUG_FS
      iio: imu: adis16460: drop ifdef around CONFIG_DEBUG_FS

 drivers/iio/imu/adis16400.c | 18 ++++--------------
 drivers/iio/imu/adis16460.c | 18 ++++--------------
 drivers/iio/imu/adis16475.c |  9 +++------
 drivers/iio/imu/adis16480.c | 18 ++++--------------
 4 files changed, 15 insertions(+), 48 deletions(-)
---
base-commit: 7cad163c39cb642ed587d3eeb37a5637ee02740f
change-id: 20240809-dev-adis-debugfs-improv-e007579b5262
--

Thanks!
- Nuno Sá

