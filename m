From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/2] iio: dac: add backend debugfs direct_reg_access
Date: Tue, 06 Aug 2024 15:35:05 +0200
Message-Id: <20240806-dev-backend-dac-direct-reg-access-v1-0-b84a6e8ee8a0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAIkmsmYC/x3NQQrCQAxG4auUrA2M01LUq4iLMflbgzBKIqVQe
 neHLr/NexsF3BB06zZyLBb2qQ3nU0fyKnUGmzZTTnlIlzSyYuFnkTeqshZhNYf82DFzEUEEp37
 Kek39WJCpdb6OydbjcX/s+x8OWFCgcwAAAA==
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722951306; l=614;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=1hhfQ+rPODIJTgb/WtLEuPJO6Ig3OVI+VHjhVBlk+lo=;
 b=DqUtGStWqNt0UrPF91SeiPaN5ZpHmk1EBnU/9GFU1xHmWVukQomBgBnlQTK0+sXNNrw9Et94h
 pp0Ee/EdkqWCy4z+EzFnSDTokgomh22T7kxSVMKQBD79kVEme7M5ODK
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Implement the direct_reg_access callback in the axi-dac backend driver.
On the ad9739a frontend, call iio_backend_debugfs_add() to add the
backend debugfs interface.

---
Nuno Sa (2):
      iio: dac: adi-axi-dac: support debugfs direct_reg_access
      iio: dac: ad9739a: add backend debugfs interface

 drivers/iio/dac/ad9739a.c     |  8 +++++++-
 drivers/iio/dac/adi-axi-dac.c | 12 ++++++++++++
 2 files changed, 19 insertions(+), 1 deletion(-)
---
base-commit: 593737c18ae789dc6e4b493510a0c00977972e2e
change-id: 20240806-dev-backend-dac-direct-reg-access-03f2d9036ae2
--

Thanks!
- Nuno Sá

