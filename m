From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH v2 0/8] iio: adc: ad9467: add debugFS test mode support
Date: Fri, 02 Aug 2024 16:26:58 +0200
Message-Id: <20240802-dev-iio-backend-add-debugfs-v2-0-4cb62852f0d0@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIALLsrGYC/x3MMQqAMAxA0atIZgO1VRSvIg6NiRqEKi2KIN7d4
 vj+8B9IElUS9MUDUS5NuocMWxYwrT4sgsrZYI2tTWcsslyouiP5aZPA6Jlzo3OZExqqHFHjG3I
 t5MMRZdb7vw/j+37W5c5PbQAAAA==
To: linux-iio@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, 
 Olivier Moysan <olivier.moysan@foss.st.com>, 
 Dragos Bogdan <dragos.bogdan@analog.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722608829; l=2012;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=pvtbbtM2BoSZ+0w2lcuO7Y9dGXHbuMOSI1xg+oSvlaQ=;
 b=Y9hCuzr4UYA793TawdundcDsEfDhbDAsfJEzLTq8dQo5JLQUuDCps1upTM/PswH4PLYWbOpRg
 cLHhBbcbX2RDz2AVCElwLoESrNUi0VdZK5c3u1hBZXrkn9xiQmWqDQS
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is the second version of the series. I ended up trying the new
directory route and think it does look nice and more future proof.
Biggest change is the first patch where we now pass an info like
structure to devm_iio_backend_register(). Again, this is likely also a more
future proof approach and we would likely need it sooner or later (one
usage I see is for backends to pass in some constant information that
could be consumed from frontends when doing backend_get())  

v1:
 * https://lore.kernel.org/linux-iio/20240709-dev-iio-backend-add-debugfs-v1-0-fb4b8f2373c7@analog.com/

v2:
 * Patch 1:
  - New patch;

 * Patch 2:
  - Added backendY directory with the direct_reg_access and name
    attributes;
  - Get the backend name directly from the backend driver;
  - Get the backend index from backend-names FW property;
  - Added debugfs-iio-backend to the ABI docs. 

---
Nuno Sa (8):
      iio: backend: introduce struct iio_backend_info
      iio: backend: add debugFs interface
      iio: backend: add a modified prbs23 support
      iio: adc: adi-axi-adc: support modified prbs23
      iio: adc: adi-axi-adc: split axi_adc_chan_status()
      iio: adc: adi-axi-adc: implement backend debugfs interface
      iio: adc: ad9467: add backend test mode helpers
      iio: adc: ad9467: add digital interface test to debugfs

 Documentation/ABI/testing/debugfs-iio-backend |  20 ++
 MAINTAINERS                                   |   1 +
 drivers/iio/adc/ad9467.c                      | 255 +++++++++++++++++++++++---
 drivers/iio/adc/adi-axi-adc.c                 |  71 ++++++-
 drivers/iio/dac/adi-axi-dac.c                 |   7 +-
 drivers/iio/industrialio-backend.c            | 155 +++++++++++++++-
 include/linux/iio/backend.h                   |  28 ++-
 7 files changed, 499 insertions(+), 38 deletions(-)
---
base-commit: 168bed989d651794d03638e1f7f7b5a800a6f425
change-id: 20240802-dev-iio-backend-add-debugfs-0b13bb5a5b37
--

Thanks!
- Nuno Sá

