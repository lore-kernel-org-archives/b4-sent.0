From: Nuno Sa <nuno.sa@analog.com>
Subject: [PATCH 0/5] iio: move IIO to the cleanup.h magic
Date: Wed, 21 Feb 2024 14:26:51 +0100
Message-Id: <20240221-iio-use-cleanup-magic-v1-0-f9c292666f26@analog.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIABv61WUC/x3MQQqAIBBA0avErBvQIYS6SrQwG2ugNJQikO6et
 HyL/wtkTsIZhqZA4luyxFCh2wbcZsPKKEs1kKJOkTYoEvHKjG5nG64TD7uKQ+q9M8ZY3dEMtT0
 Te3n+7zi97wdLImL0ZwAAAA==
To: linux-iio@vger.kernel.org
Cc: Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>, Nuno Sa <nuno.sa@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708522015; l=1716;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=biPceoEZ/pR8Xvp5/lPe0+nInLOTnUmJdiVykHTBK1w=;
 b=AUaQQPhJDVV4uNENBLF+EKn+PL4QP1S428oUWvtL458297kN79a0df7Udu8l3Cz60OM1fsoM+
 EpPGSQMElCSAkBtul2u4Zv9sV8CI42wpoDs6gOyUp3SNFKzW9EkpBM/
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series moves the main IIO core files to the new cleanup.h
macros for acquiring and automatically releasing mutexes. This results (in
some cases) in way simpler code paths.

I think the overall result is fairly neat (mainly in inkern.c).

One thing to mention is in the iio_event_getfd() function. We might be
changing the return code. Before we directly returned the error code
returned by mutex_lock_interruptible(). Now we return -EINTR. And this
is something visible by userspace so it might mean an ABI breakage.

Having said the above, looking at the mutex_lock_interruptible() docs it
seems we either return 0 or -EINTR. Not sure if that is really truth
(but it does makes sense). On top of that, I would also say it's very
unlikely for someone to be relying on an error code return by a locking
function but who knows... Anyways, this is something worth mentioning.

Next goal is to convert the code under iio/buffer/

---
Nuno Sa (5):
      iio: core: move to cleanup.h magic
      iio: events: move to the cleanup.h magic
      iio: trigger: move to the cleanup.h magic
      iio: buffer: iio: core: move to the cleanup.h magic
      iio: inkern: move to the cleanup.h magic

 drivers/iio/industrialio-buffer.c  | 105 +++++++----------
 drivers/iio/industrialio-core.c    |  52 ++++-----
 drivers/iio/industrialio-event.c   |  42 +++----
 drivers/iio/industrialio-trigger.c |  64 +++++------
 drivers/iio/inkern.c               | 224 ++++++++++++-------------------------
 5 files changed, 172 insertions(+), 315 deletions(-)
---
base-commit: bd2f1ed8873d4bbb2798151bbe28c86565251cfb
change-id: 20240216-iio-use-cleanup-magic-29fc666a142b
--

Thanks!
- Nuno Sá

